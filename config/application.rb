require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module PlaceosAuth
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = false
    config.action_dispatch.use_cookies_with_metadata = false

    # Fix 404 routing for logging
    config.after_initialize do |app|
      app.routes.append do
        match "*any", via: :all, to: "errors#not_found"
      end
    end
  end
end
