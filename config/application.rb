# encoding: UTF-8

require_relative 'boot'

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
# require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
# require "action_cable/engine"
# require "sprockets/railtie"
require "rails/test_unit/railtie"

require "nobrainer"
require_relative 'nobrainer_monkey_patch'
require_relative "../app/models/concerns/auth_timestamps"
require_relative "../app/models/authority"
require_relative "../app/models/user"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module EngineApp
  class Application < Rails::Application
    config.load_defaults "6.0"

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = false
    config.action_dispatch.use_cookies_with_metadata = false

    # Selectively switch between API and full rails stacks
    config.before_initialize do |app|
      # Authentication stack is different
      # app.config.middleware.insert_after Rack::Runtime, ::ActionDispatch::Flash
      # app.config.middleware.insert_after Rack::Runtime, ::OmniAuth::Builder, &OmniAuthConfig
      # app.config.middleware.insert_after Rack::Runtime, ::Rails.application.config.session_options
      # app.config.middleware.insert_after Rack::Runtime, ::ActionDispatch::Cookies
    end

    config.after_initialize do |app|
      # Fix 404 routing for logging
      app.routes.append do
        match "*any", via: :all, to: 'errors#not_found'
      end

      # Ensure indeses are synced
      NoBrainer.sync_indexes
    end
  end
end
