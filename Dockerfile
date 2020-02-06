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


EXPOSE 8080
ENTRYPOINT rails s -b 0.0.0.0 -p 8080
