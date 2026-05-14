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
require_relative "../../lib/omniauth/strategies/generic_oauth"

require_relative "../../app/models/ldap_strat"
require_relative "../../lib/omniauth/strategies/generic_ldap"

require_relative "../../app/models/adfs_strat"
require_relative "../../lib/omniauth/strategies/generic_adfs"

# see /app/middleware/selective_stack.rb for usage
# This allows us to use omniauth with Rails API stack
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :developer unless Rails.env.production?
  provider :generic_adfs, name: "adfs"
  provider :generic_ldap, name: "ldap"
  provider :generic_oauth, name: "oauth2"
end

require "singleton"
require "thread"

class LoginEvent
  include Singleton

  QUEUE_SIZE = 500

   def configure(redis:)
    return self if @configured || redis.nil?

    @redis = redis
    @queue = SizedQueue.new(QUEUE_SIZE)
    @configured = true
    @thread = Thread.new { run }

    self
  end

  def push(user, provider)
    @queue.push([user.id, provider], true)
  rescue
    puts "WARN: login event queue full, dropping event"
  end

  private

  def initialize
    @configured = false
  end

  def run
    loop do
      process(*@queue.pop)
    end
  end

  def process(user_id, provider)
    puts "INFO: sending login event"
    @redis.publish("placeos/auth/login", {user_id: user_id, provider: provider}.to_json)
  rescue => e
    puts "error signalling login: #{e.class} #{e.message}"
  end
end

require "redis"

# Notify PlaceOS of the recent authentication
# Allows drivers to implement custom `after_login` actions like obtaining LDAP groups etc
AUTH_REDIS_URL = ENV["REDIS_URL"]
REDIS_CLIENT = if AUTH_REDIS_URL
  Redis.new(
    url: AUTH_REDIS_URL,
    connect_timeout: 2.0,
    timeout: 2.0,
    reconnect_attempts: [0.1, 0.5]
  )
else
  puts "WARN: redis client not configured, login events will not be sent"
  nil
end

LOGIN_EVENTS = LoginEvent.instance.configure(redis: REDIS_CLIENT)

Authentication.after_login do |user, provider, _auth|
  if REDIS_CLIENT
    begin
      LOGIN_EVENTS.push(user, provider)
    rescue => e
      puts "error queueing login event: #{e.class} #{e.message}"
    end
  else
    puts "\n\nWARN: redis client not configured, login event ignored\n"
  end
  user.update_columns(login_count: user.login_count + 1, last_login: Time.now) rescue nil
end
