ARG RUBY_VER="3.3"
##############################
# 1) BUILD STAGE
##############################
FROM ruby:$RUBY_VER-alpine AS build-env

# 1a) Packages required to build native extensions + runtime libs
#    (e.g. if you need xml or postgres in production).
ARG BUILD_PACKAGES="build-base curl-dev libxml2-dev libxslt-dev zlib-dev libpq-dev yaml-dev git"
# 1b) Minimal runtime libraries you actually need
#    (remove anything you do not actually use in production)
ARG RUNTIME_PACKAGES="tzdata libxml2 libxslt curl zlib libpq yaml"

ENV RAILS_ENV=production \
    RACK_ENV=production \
    # Exclude dev/test gems so they’re not installed at all
    BUNDLE_WITHOUT=development:test \
    BUNDLE_FROZEN=1 \
    # Where gems will live in the image
    BUNDLE_PATH=/app/vendor/bundle

RUN apk add --no-cache $BUILD_PACKAGES $RUNTIME_PACKAGES

# Optional: If you do NOT strictly need a correct timezone in production,
# you can remove tzdata to save a few MB:
# RUN apk add --no-cache $BUILD_PACKAGES $RUNTIME_PACKAGES && \
#     apk del tzdata

# Set timezone if needed
RUN cp /usr/share/zoneinfo/Australia/Sydney /etc/localtime && \
    echo "Australia/Sydney" > /etc/timezone

WORKDIR /app

# Copy Gemfiles first for layer caching
COPY Gemfile* ./

# Install bundler (no docs)
RUN gem install bundler --no-document

# Install production gems
RUN bundle install -j2 --retry 3

# Copy the rest of your Rails code
COPY . .

# Remove any stale binstubs referencing dev/test gems
RUN rm -rf bin/*

# Instead of `bundle binstubs bundler`, which triggers dev/test checks,
# just binstub puma (or skip binstubs entirely and use `bundle exec puma`)
RUN bundle binstubs puma --force

# Clean up gem caches, .o/.c files, leftover test dirs
RUN rm -rf vendor/bundle/ruby/3.3.0/cache/*.gem && \
    find vendor/bundle/ruby/3.3.0/gems/ -name "*.c" -delete && \
    find vendor/bundle/ruby/3.3.0/gems/ -name "*.o" -delete && \
    rm -rf tmp/pids spec

##############################
# 2) FINAL STAGE
##############################
FROM ruby:$RUBY_VER-alpine

# Keep only the minimal runtime libs you truly need in production
ARG RUNTIME_PACKAGES="libxml2 libxslt curl zlib libpq yaml tzdata"
RUN apk add --no-cache $RUNTIME_PACKAGES

# Again, if tzdata is not strictly needed, omit it:
# RUN apk add --no-cache libxml2 libxslt curl zlib libpq yaml

# Optional: set timezone if you kept tzdata
RUN cp /usr/share/zoneinfo/Australia/Sydney /etc/localtime && \
    echo "Australia/Sydney" > /etc/timezone

ENV APP_DIR="/app"
WORKDIR $APP_DIR

# Keep same environment so bundler won't look for dev/test
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
HEALTHCHECK CMD ["wget","--no-verbose","-q","--spider","http://0.0.0.0:8080/auth/authority?health=true"]

# Use `bundle exec puma` if you prefer. 
# If you *only* generated `bin/puma` (and not `bin/bundle`), then:
ENTRYPOINT ["./bin/puma", "-b", "tcp://0.0.0.0:8080"]

# Or (if you didn't generate a puma binstub at all) do:
# ENTRYPOINT ["bundle", "exec", "puma", "-b", "tcp://0.0.0.0:8080"]
