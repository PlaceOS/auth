# encoding: UTF-8

require 'jwt'
require 'net/http'

class ApplicationController < ActionController::Base
  skip_before_action :verify_authenticity_token

  PLACE_URI = ENV["PLACE_URI"].presence || abort("PLACE_URI not in environment")

  PUBLIC_KEY = OpenSSL::PKey::RSA.new(Doorkeeper::JWT.configuration.secret_key).public_key

  SENTRY_CONFIGURED = !!ENV["SENTRY_DSN"]
  if SENTRY_CONFIGURED
    before_action :set_raven_context
  end

  protected

  def get_jwt
    return @jwt_token if @jwt_token

    if (token = request.headers["X-API-Key"])
      uri = URI(PLACE_URI)
      uri.path = "/api/engine/v2/api_keys/inspect"
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.instance_of? URI::HTTPS

      # build request
      req = Net::HTTP::Get.new(uri.request_uri)
      req["Host"] = request.headers["Host"]
      req["Accept"] = "application/json"
      req["X-API-Key"] = request.headers["X-API-Key"]

      # check API key
      res = http.request(req)
      if res.is_a?(Net::HTTPSuccess)
        @jwt_token = JSON.parse(res.body)
        return @jwt_token
      end
    end

    token = request.headers["Authorization"]
    if token
      token = token.split("Bearer ")[1].rstrip
      token = nil unless token.presence
    else
      token = params["bearer_token"]
      token.strip if token
      token = nil unless token.presence
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
