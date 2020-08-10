# encoding: UTF-8

module CurrentAuthorityHelper
  def current_authority
    @current_authority ||= Authority.find_by_domain(request.host)
  end
end
