FROM ruby:2.6-alpine

RUN apk update && \
    apk add tzdata git && \
    cp /usr/share/zoneinfo/Australia/Sydney /etc/localtime && \
    echo "Australia/Sydney" > /etc/timezone

RUN apk add --no-cache libxml2 libxslt && \
    apk add --no-cache --virtual .gem-installdeps build-base libxml2-dev libxslt-dev

ENV APP_DIR /app
RUN mkdir $APP_DIR
WORKDIR $APP_DIR

ADD Gemfile* $APP_DIR/
RUN bundle install

ADD . $APP_DIR

RUN rm -rf /app/tmp/pids/
RUN rm -rf $GEM_HOME/cache && \
    apk del .gem-installdeps

# Create a non-privileged user
# defaults are appuser:10001
ARG IMAGE_UID="10001"
ENV UID=$IMAGE_UID
ENV USER=appuser

# See https://stackoverflow.com/a/55757473/12429735RUN
RUN adduser -D -g "" -h "/nonexistent" -s "/sbin/nologin" -H -u "${UID}" "${USER}"

RUN chown appuser:appuser -R /app/tmp

# Use an unprivileged user.
USER appuser:appuser

EXPOSE 8080
ENTRYPOINT rm -rf /app/tmp/pids/server.pid && rails s -b 0.0.0.0 -p 8080
