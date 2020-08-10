# encoding: UTF-8

require 'jwt'

class ApplicationController < ActionController::Base
  skip_before_action :verify_authenticity_token

  PUBLIC_KEY = OpenSSL::PKey::RSA.new(Doorkeeper::JWT.configuration.secret_key).public_key

  SENTRY_CONFIGURED = !!ENV["SENTRY_DSN"]
  if SENTRY_CONFIGURED
    before_action :set_raven_context
  end

  protected

  def get_jwt
    return @jwt_token if @jwt_token

    token = request.headers["Authorization"]
    if token
      token = token.split("Bearer ")[1].rstrip
      token = nil if token.empty?
    else
      token = params["bearer_token"]
      token.strip if token
      token = nil if token.empty?
    end

    if token
      @jwt_token = JWT.decode token, get_public_key, true, { algorithm: 'RS256' }
    end
  end

  private

  def set_raven_context
    user = cookies.encrypted[:user]
    Raven.user_context(id: user[:id] || user['id']) if user
    Raven.extra_context(url: request.original_url, remote_ip: request.remote_ip)
  end

  def get_public_key
    PUBLIC_KEY
  end
end
