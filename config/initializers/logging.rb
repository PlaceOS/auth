# encoding: UTF-8

# Be sure to restart your server when you modify this file.

# Configure sensitive parameters which will be filtered from the log file.
Rails.application.config.filter_parameters += [:password]

# Sentry DSN looks like: 'http://f0e5cf1431f24936ba99b7dc2bbc1af0:ac94cdf93bfb480ea45dd8889c97a817@sentry:8989/1'
# Note replace the sentry host with the container DNS "sentry"
sentry_dsn = ENV["SENTRY_DSN"]
if sentry_dsn
  Raven.configure do |config|
    config.dsn = sentry_dsn
    config.sanitize_fields = Rails.application.config.filter_parameters.map(&:to_s)
  end
end
