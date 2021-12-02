# frozen_string_literal: true

module CurrentAuthorityHelper
  def current_authority
    @current_authority ||= Authority.find_by_domain(request.host)
  end
end
