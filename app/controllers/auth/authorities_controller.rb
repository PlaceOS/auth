# frozen_string_literal: true

module Auth
  class AuthoritiesController < ApplicationController
    include UserHelper
    include CurrentAuthorityHelper

    def current
      authority = current_authority
      if authority
        auth = authority.as_json(except: %i[created_at internals])
        auth[:version] = "v2.0.0"
        auth[:session] = signed_in?

        begin
          access_token = doorkeeper_token
          if access_token
            access_token.revoke_previous_refresh_token!
            auth[:token_valid] = true
            configure_asset_access
          else
            auth[:token_valid] = false
          end
        rescue
          auth[:token_valid] = false
        end
        auth[:production] = Rails.env.production?
        render json: auth
      else
        # so we can use this route as a health check it will always return 200
        # if `?health` param is set and fail if the database connection is down
        head(params.key?(:health) ? :ok : :not_found)
      end
    end
  end
end
