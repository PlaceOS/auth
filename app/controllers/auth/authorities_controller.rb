# frozen_string_literal: true

module Auth
  class AuthoritiesController < ApplicationController
    include UserHelper
    include CurrentAuthorityHelper

    def current
      authority = current_authority
      if authority
        auth = authority.as_json(except: [:created_at, :internals])
        auth[:version] = "v2.0.0"
        begin
          auth[:session] = signed_in?
        rescue
          auth[:session] = false
        end
        auth[:production] = Rails.env.production?
        render json: auth
      else
        head :not_found
      end
    end
  end
end
