# encoding: UTF-8

require 'securerandom'

module Auth
  class CoauthController < ApplicationController
    include UserHelper
    include CurrentAuthorityHelper

    Rails.application.config.force_ssl = Rails.env.production? && (ENV['COAUTH_NO_SSL'].nil? || ENV['COAUTH_NO_SSL'] == 'false')
    USE_SSL = Rails.application.config.force_ssl

    def success_path
      '/login_success.html'
    end

    def login_path
      '/login'
    end

    protected

    def new_session(user)
        @current_user = user
        value = {
          value: {
            id: user.id,
            expires: 1.day.from_now.to_i
          },
          httponly: true,
          path: '/auth'   # only sent to calls at this path
        }
        value[:secure] = USE_SSL
        cookies.encrypted[:user] = value
    end

    def store_social(uid, provider)
      value = {
        value: {
          uid: uid,
          provider: provider,
          expires: 1.hour.from_now.to_i
        },
        httponly: true,
        path: '/auth'   # only sent to calls at this path
      }
      value[:secure] = USE_SSL
      cookies.encrypted[:social] = value
    end

    def set_continue(path)
      if path.include?("://")
        uri = Addressable::URI.parse(path)
        path = "#{uri.request_uri}#{uri.fragment ? "##{uri.fragment}" : nil}"
      end

      value = {
        value: path,
        httponly: true,
        path: '/auth'   # only sent to calls at this path
      }
      value[:secure] = USE_SSL
      cookies.encrypted[:continue] = value
    end
  end
end
