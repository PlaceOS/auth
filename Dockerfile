ARG RUBY_VER="3.4"
FROM ruby:$RUBY_VER-alpine AS build-env

# Include openssl-dev for Puma and gumbo for Nokogiri’s libgumbo support
ARG BUILD_PACKAGES="build-base curl-dev libxml2-dev libxslt-dev zlib-dev libpq-dev yaml-dev git openssl-dev"
# Add gumbo to runtime packages (if you need it at build time for Nokogiri, you might add it here as well)
ARG RUNTIME_PACKAGES="tzdata libxml2 libxslt curl zlib libpq yaml gumbo-parser"

ENV RAILS_ENV=production \
    RACK_ENV=production \
    BUNDLE_WITHOUT=development:test \
    BUNDLE_FROZEN=1 \
    BUNDLE_PATH=/app/vendor/bundle

RUN apk add --no-cache $BUILD_PACKAGES $RUNTIME_PACKAGES

# Set timezone
RUN cp /usr/share/zoneinfo/Australia/Sydney /etc/localtime && \
    echo "Australia/Sydney" > /etc/timezone

WORKDIR /app

# Copy Gemfiles for caching
COPY Gemfile* ./

# Tell Nokogiri to use system libraries, including the system libgumbo
RUN bundle config build.nokogiri --use-system-libraries
RUN bundle config --global build.nokogiri --use-system-libraries

# Optionally lower optimization to avoid compiler issues
ENV CFLAGS="-O0"

# Install bundler and gems
RUN gem install bundler --no-document
RUN bundle install -j1 --retry 3

# Continue with the rest of your build...
COPY . .

# Remove any stale binstubs referencing dev/test gems
RUN rm -rf bin/*

# Generate binstubs for Puma
RUN bundle binstubs puma --force

# Clean up gem caches, .o/.c files, leftover test dirs
RUN rm -rf vendor/bundle/ruby/3.4.0/cache/*.gem && \
    find vendor/bundle/ruby/3.4.0/gems/ -name "*.c" -delete && \
    find vendor/bundle/ruby/3.4.0/gems/ -name "*.o" -delete && \
    rm -rf tmp/pids spec

##############################
# 2) FINAL STAGE
##############################
FROM ruby:$RUBY_VER-alpine

RUN apk update && apk --no-cache --quiet upgrade

ARG RUNTIME_PACKAGES="libxml2 libxslt curl zlib libpq yaml tzdata"
RUN apk add --no-cache $RUNTIME_PACKAGES

RUN cp /usr/share/zoneinfo/Australia/Sydney /etc/localtime && \
    echo "Australia/Sydney" > /etc/timezone

ENV APP_DIR="/app"
WORKDIR $APP_DIR

ENV RAILS_ENV=production \
    RACK_ENV=production \
    BUNDLE_WITHOUT=development:test \
    BUNDLE_FROZEN=1 \
    BUNDLE_PATH=$APP_DIR/vendor/bundle

# Copy only the fully built app (with installed gems) from builder
COPY --from=build-env /app /app

# Create non-privileged user
ARG IMAGE_UID="10001"
RUN adduser -D -g "" -h "/nonexistent" -s "/sbin/nologin" -H -u "${IMAGE_UID}" appuser && \
    chown -R appuser:appuser $APP_DIR

USER appuser
EXPOSE 8080

# Healthcheck, optional
HEALTHCHECK CMD ["wget", "--no-verbose", "-q", "--spider", "http://0.0.0.0:8080/auth/authority?health=true"]

ENTRYPOINT ["./bin/puma", "-b", "tcp://0.0.0.0:8080"]
