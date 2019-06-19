FROM ruby:2.6.3

ENV APP_DIR /app
RUN mkdir $APP_DIR
WORKDIR $APP_DIR

ADD Gemfile* $APP_DIR/
RUN bundle install

ADD . $APP_DIR

EXPOSE 8080
ENTRYPOINT ["rails", "c"]
CMD ["rails", "s", "-p", "8080"]
