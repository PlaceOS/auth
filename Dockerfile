ARG RUBY_VER="3.3"
##############################
# 1) BUILD STAGE
##############################
FROM ruby:$RUBY_VER-alpine AS build-env

# 1a) Packages required to build native extensions + runtime libs
ARG BUILD_PACKAGES="build-base curl-dev libxml2-dev libxslt-dev zlib-dev libpq-dev yaml-dev git"
ARG RUNTIME_PACKAGES="tzdata libxml2 libxslt curl zlib libpq yaml"

ENV RAILS_ENV=production \
    RACK_ENV=production \
    BUNDLE_WITHOUT=development:test \
    BUNDLE_FROZEN=1 \
    BUNDLE_PATH=/app/vendor/bundle

RUN apk add --no-cache $BUILD_PACKAGES $RUNTIME_PACKAGES

RUN cp /usr/share/zoneinfo/Australia/Sydney /etc/localtime && \
    echo "Australia/Sydney" > /etc/timezone

WORKDIR /app

# Copy Gemfiles first for layer caching
COPY Gemfile* ./

# Configure bundler for Nokogiri to use system libraries
RUN bundle config build.nokogiri --use-system-libraries

# Install bundler (no docs)
RUN gem install bundler --no-document

# Install production gems
RUN bundle install -j2 --retry 3

# Copy the rest of your Rails code
COPY . .

RUN rm -rf bin/*
RUN bundle binstubs puma --force

RUN rm -rf vendor/bundle/ruby/3.3.0/cache/*.gem && \
    find vendor/bundle/ruby/3.3.0/gems/ -name "*.c" -delete && \
    find vendor/bundle/ruby/3.3.0/gems/ -name "*.o" -delete && \
    rm -rf tmp/pids spec

##############################
# 2) FINAL STAGE
##############################
FROM ruby:$RUBY_VER-alpine

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

COPY --from=build-env /app /app

ARG IMAGE_UID="10001"
RUN adduser -D -g "" -h "/nonexistent" -s "/sbin/nologin" -H -u "${IMAGE_UID}" appuser && \
    chown -R appuser:appuser $APP_DIR

USER appuser
EXPOSE 8080

HEALTHCHECK CMD ["wget","--no-verbose","-q","--spider","http://0.0.0.0:8080/auth/authority?health=true"]

ENTRYPOINT ["./bin/puma", "-b", "tcp://0.0.0.0:8080"]
