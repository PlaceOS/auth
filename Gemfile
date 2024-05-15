source "https://rubygems.org"

gem "rails", "~> 7.1.3"

# We don't use the mail gem
gem "net-smtp", require: false
gem "net-imap", require: false
gem "net-pop", require: false

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# High performance web server
gem "puma"

# Database
gem "pg"
gem "redis"

# Authentication
gem "doorkeeper", "~> 5.6"
gem "doorkeeper-jwt"
gem "jwt"
gem "nkf" # required for omniauth-oauth2 in Ruby 3.4
gem "omniauth", "~> 1.9"
gem "omniauth-ldap2"
gem "omniauth-oauth2"
gem "omniauth-saml"

# Model support
gem "addressable"
gem "bcrypt"
gem "email_validator"

# Logging
gem "lograge"
gem "logstash-event"
gem "mono_logger"
gem "sentry-ruby"
gem "opentelemetry-sdk"
gem "opentelemetry-exporter-otlp"
gem "opentelemetry-instrumentation-all"

# Runtime debugging
gem "rbtrace"

# Fast JSON parsing
gem "yajl-ruby"
gem "multi_json"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri mingw x64_mingw ]
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"
  gem "pry-rails"
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "capybara"
  gem "selenium-webdriver"
  gem "webdrivers"
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ mingw mswin x64_mingw jruby ]
