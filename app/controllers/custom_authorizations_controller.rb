# frozen_string_literal: true

class CustomAuthorizationsController < Doorkeeper::AuthorizationsController
  include AbstractController::Callbacks

  after_action :expose_location_header

  # Allow redirect to be handled in AJAX land for inline auth
  def expose_location_header
    response.headers['Access-Control-Expose-Headers'] = 'Location'
  end
end
