# frozen_string_literal: true

require "securerandom"

module Auth
  class CoauthController < ApplicationController
    include UserHelper
    include CurrentAuthorityHelper

    Rails.application.config.force_ssl = true
    USE_SSL = Rails.application.config.force_ssl

    def success_path
      "/login_success.html"
    end

    def login_path
      "/login"
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

      redirect_to path, allow_other_host: true
    end

    def new_session(user)
      @current_user = user

      # default is 1 day
      session_valid = (current_authority.internals["session_timeout"] || "24").to_i.hours.from_now

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
      cookies.signed[:verified] = {
        value: session_valid.to_i.to_s,
        expires: session_valid,
        secure: USE_SSL,
        httponly: true,
        same_site: :none,
        path: "/"
      }
    end

    # TODO:: complete this
    def api_key_valid?(api_key)
      true
    end

    def configure_api_key_access
      session_valid = 20.years

      cookies.signed[:verified] = {
        value: session_valid.to_i.to_s,
        expires: session_valid,
        secure: USE_SSL,
        httponly: true,
        same_site: :none,
        path: "/"
      }
    end

    def store_social(uid, provider)
      value = {
        value: {
          uid: uid,
          provider: provider,
          expires: 1.hour.from_now.to_i
        },
        expires: 1.hour,
        secure: USE_SSL,
        httponly: true,
        path: "/auth" # only sent to calls at this path
      }
      cookies.encrypted[:social] = value
    end

    def set_continue(path)
      path ||= "/"

      if !path.start_with?("/") || path.include?("//")
        uri = Addressable::URI.parse(path)
        path = "#{uri.request_uri}#{uri.fragment ? "##{uri.fragment}" : nil}"
      end

      value = {
        value: path,
        httponly: true,
        secure: USE_SSL,
        same_site: :none,
        path: "/auth" # only sent to calls at this path
      }
      cookies.encrypted[:continue] = value
    end
  end
end
