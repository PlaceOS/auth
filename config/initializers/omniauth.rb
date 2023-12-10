# frozen_string_literal: true

require "omniauth"

Rails.application.config.session_store :cookie_store,
  key: "_coauth_session",
  secure: Rails.env.production?

require_relative "../../app/models/authentication"
require_relative "../../app/models/authority"
require_relative "../../app/models/user"

require_relative "../../app/helpers/current_authority_helper"

require_relative "../../app/models/oauth_strat"
require "omniauth/strategies/generic_oauth"

require_relative "../../app/models/ldap_strat"
require "omniauth/strategies/generic_ldap"

require_relative "../../app/models/adfs_strat"
require "omniauth/strategies/generic_adfs"

# see /app/middleware/selective_stack.rb for usage
# This allows us to use omniauth with Rails API stack
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :developer unless Rails.env.production?
  provider :generic_adfs, name: "adfs"
  provider :generic_ldap, name: "ldap"
  provider :generic_oauth, name: "oauth2"
end

require "redis"

# Notify PlaceOS of the recent authentication
# Allows drivers to implement custom `after_login` actions like obtaining LDAP groups etc
AUTH_REDIS_URL = ENV["REDIS_URL"]
REDIS_CLIENT = if AUTH_REDIS_URL
  Redis.new(url: AUTH_REDIS_URL)
else
  puts "WARN: redis client not configured, login events will not be sent"
  nil
end

Authentication.after_login do |user, provider, _auth|
  if REDIS_CLIENT
    begin
      puts "INFO: sending login event"
      REDIS_CLIENT.publish("placeos/auth/login", {user_id: user.id, provider: provider}.to_json)
    rescue => e
      puts "error signalling login: #{e.message}"
    end
  else
    puts "\n\nWARN: redis client not configured, login event ignored\n"
  end
  user.update_columns(login_count: user.login_count + 1, last_login: Time.now)
end
