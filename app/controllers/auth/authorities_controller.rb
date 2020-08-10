# encoding: UTF-8

module Auth
  class AuthoritiesController < ApplicationController
    include UserHelper
    include CurrentAuthorityHelper

    def current
      authority = current_authority
      if authority
        auth = authority.as_json(except: [:created_at, :internals])
        auth[:version] = "v2.0.0"
        auth[:session] = signed_in?
        begin
          access_token = doorkeeper_token
          if access_token
            access_token.revoke_previous_refresh_token!
            auth[:token_valid] = true
          else
            auth[:token_valid] = false
          end
        rescue
          auth[:token_valid] = false
        end
        auth[:production] = Rails.env.production?
        render json: auth
      else
        head :not_found
      end
    end
  end
end
