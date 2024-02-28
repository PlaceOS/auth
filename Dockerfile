ARG RUBY_VER="3.3"
FROM ruby:$RUBY_VER-alpine AS build-env

ARG PACKAGES="git libxml2 libxslt build-base curl-dev libxml2-dev libxslt-dev zlib-dev tzdata libpq-dev"

RUN apk update && \
    apk upgrade && \
    apk add --update --no-cache $PACKAGES && \
    cp /usr/share/zoneinfo/Australia/Sydney /etc/localtime && \
    echo "Australia/Sydney" > /etc/timezone

ENV APP_DIR /app
RUN mkdir $APP_DIR
WORKDIR $APP_DIR

ENV BUNDLE_APP_CONFIG="$APP_DIR/.bundle"

COPY Gemfile* $APP_DIR/
RUN gem install bundler
RUN bundle config set without 'test:assets'
RUN bundle config set --local path 'vendor/bundle'
RUN bundle config --global frozen 1 \
    && bundle install -j4 --retry 3 \
    && bundle binstubs puma --force \
    # Remove unneeded files (cached *.gem, *.o, *.c)
    && rm -rf vendor/bundle/ruby/3.3.0/cache/*.gem \
    && find vendor/bundle/ruby/3.3.0/gems/ -name "*.c" -delete \
    && find vendor/bundle/ruby/3.3.0/gems/ -name "*.o" -delete

COPY . .

RUN rm -rf /app/tmp/pids/ && rm -rf /app/spec

############### Build step done ###############

FROM ruby:$RUBY_VER-alpine

# Copy just the application to this new image
ENV APP_DIR /app
COPY --from=build-env $APP_DIR $APP_DIR
WORKDIR $APP_DIR

ENV BUNDLE_APP_CONFIG="$APP_DIR/.bundle"

# install packages
ARG PACKAGES="tzdata libxml2 libxslt libc6-compat libpq-dev"
RUN apk update \
    && apk upgrade \
    && apk add --update --no-cache $PACKAGES

# Create a non-privileged user
# defaults are appuser:10001
ARG IMAGE_UID="10001"
ENV UID=$IMAGE_UID
ENV USER=appuser

# See https://stackoverflow.com/a/55757473/12429735RUN
RUN adduser -D -g "" -h "/nonexistent" -s "/sbin/nologin" -H -u "${UID}" "${USER}"
RUN chown appuser:appuser -R /app/tmp

# NOTE:: this should not be used, instead use `RAILS_MASTER_KEY` env var
RUN chown appuser:appuser -R /app/config/
RUN bundle binstubs bundler --force

# Use an unprivileged user.
USER appuser:appuser

EXPOSE 8080
HEALTHCHECK CMD wget --no-verbose -q --spider http://0.0.0.0:8080/auth/authority?health=true
ENTRYPOINT ./bin/puma -b tcp://0.0.0.0:8080
