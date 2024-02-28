# frozen_string_literal: true

require "openssl"
require "securerandom"

module Auth
  class CoauthController < ApplicationController
    include UserHelper
    include CurrentAuthorityHelper

    Rails.application.config.force_ssl = true
    USE_SSL = true

    def success_path
      "/"
    end

    def login_path
      "/auth/login"
    end

    protected

    def redirect_continue(path)
      # checking for `.attacker.com` OR `//<external_domain>`
      # no internal paths use `//`
      check_path = path.split("?")[0]

      # need to check if redirect is configured in the DB
      if !check_path.start_with?("/") || check_path.include?("//")
        authority = current_authority
        uri = Addressable::URI.parse(path)

        path = if uri.domain == authority.domain
          "#{uri.request_uri}#{uri.fragment ? "##{uri.fragment}" : nil}"
        else
          yield
        end
      end

      redirect_to path.gsub(" ", "%20"), allow_other_host: true
    end

    def new_session(user)
      @current_user = user

      # default is 1 day (timeout in minutes)
      session_valid = (current_authority.internals["session_timeout"] || "1440").to_i.minutes.from_now

      value = {
        value: {
          id: user.id,
          expires: session_valid.to_i
        },
        expires: session_valid,
        secure: USE_SSL,
        httponly: true,
        same_site: :none,
        path: "/auth" # only sent to calls at this path
      }
      cookies.encrypted[:user] = value

      # prevent SSO redirect at nginx layer
      configure_asset_access
    end

    # Is the API key valid?
    def api_key_valid?(api_key)
      !!ApiKey.find_key!(api_key)
    rescue
      false
    end

    def store_social(uid, provider)
      value = {
        value: {
          uid: uid,
          provider: provider,
          expires: 20.minutes.from_now.to_i
        },
        expires: 20.minutes,
        secure: USE_SSL,
        httponly: true,
        path: "/auth" # only sent to calls at this path
      }
      cookies.encrypted[:social] = value
    end

    def set_continue(path)
      path ||= "/"

      # prevent adverse behaviour
      if !path.start_with?("/") || path.include?("//")
        uri = Addressable::URI.parse(path)
        path = "#{uri.request_uri}#{uri.fragment ? "##{uri.fragment}" : nil}"
      end

      value = {
        value: path,
        expires: 20.minutes,
        httponly: true,
        secure: USE_SSL,
        same_site: :none,
        path: "/auth" # only sent to calls at this path
      }
      cookies.encrypted[:continue] = value
    end
  end
end
