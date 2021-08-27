source 'https://rubygems.org'

gem 'rails', '~> 6.0', '>= 6.0.0.1'

# High performance web server
gem 'puma'

# Database
gem 'nobrainer'
gem 'redis'

# Authentication
gem 'doorkeeper', '~> 5.4'
gem 'doorkeeper-jwt'
gem 'doorkeeper-rethinkdb', git: 'https://github.com/place-labs/doorkeeper-rethinkdb.git'
gem 'omniauth', '~> 1.9'
gem 'omniauth-oauth2'
gem 'omniauth-ldap2'
gem 'omniauth-saml'
gem 'jwt'

# Uploads
gem 'condo', git: 'https://github.com/cotag/Condominios.git', branch: 'rethink-update'
gem 'condo-rethinkdb', git: 'https://github.com/place-labs/condo-rethinkdb.git'

# Model support
gem 'email_validator'
gem 'addressable'
gem 'bcrypt'

# Logging
gem 'sentry-raven'
gem 'mono_logger'
gem 'lograge'
gem 'logstash-event'
gem 'multiio'

# Runtime debugging
gem 'rbtrace'

# Fast JSON parsing
gem 'yajl-ruby'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug',      platform: :mri
  gem 'web-console', platform: :mri
  gem 'pry-rails',   platform: :mri
end

group :development do
  gem 'listen', '~> 3.0.5'

  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  #gem 'spring'
  #gem 'spring-watcher-listen', '~> 2.0.0'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data'  #, platforms: [:mingw, :mswin, :x64_mingw, :jruby]
