# frozen_string_literal: true

require "openssl"
require "securerandom"

module CurrentAuthorityHelper
  def current_authority
    @current_authority ||= Authority.find_by_domain(request.host)
  end

  SECRET = Rails.application.secret_key_base

  def configure_asset_access
    session_valid = 19.years

    data = SecureRandom.hex(8)
    digest = OpenSSL::Digest.new('sha256')
    hmac = OpenSSL::HMAC.hexdigest(digest, SECRET, data)

    cookies[:verified] = {
      value: "#{data}.#{hmac}",
      expires: session_valid,
      secure: true,
      httponly: true,
      same_site: :none,
      path: "/"
    }
  end
end
