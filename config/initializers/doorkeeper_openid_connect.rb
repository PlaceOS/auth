# frozen_string_literal: true

require "uri"

Doorkeeper::OpenidConnect.configure do
  issuer do |request|
    "https://#{request.host}"
  end

  # Set the encryption secret. This would be shared with any other applications
  # that should be able to read the payload of the token. Defaults to "secret".
  key = ENV["JWT_SECRET"]
  key = key.try { |k| Base64.decode64(k) } || DEV_KEY
  signing_key key

  subject_types_supported [:public]

  resource_owner_from_access_token do |access_token|
    User.find_by(id: access_token.resource_owner_id)
  end

  auth_time_from_resource_owner do |resource_owner|
    resource_owner.last_login
  end

  reauthenticate_resource_owner do |resource_owner, return_to|
    # Example implementation:
    # store_location_for resource_owner, return_to
    # sign_out resource_owner
    # redirect_to new_user_session_url
    domain = "https://#{request.host}"
    authority = Authority.find_by_domain(request.host)
    url = authority.login_url.gsub("{{url}}", URI.encode_uri_component(return_to))

    redirect_to "#{domain}#{url}"
  end

  # Depending on your configuration, a DoubleRenderError could be raised
  # if render/redirect_to is called at some point before this callback is executed.
  # To avoid the DoubleRenderError, you could add these two lines at the beginning
  #  of this callback: (Reference: https://github.com/rails/rails/issues/25106)
  #   self.response_body = nil
  #   @_response_body = nil
  select_account_for_resource_owner do |resource_owner, return_to|
    self.response_body = nil
    @_response_body = nil

    # there is no account selection in PlaceOS
    redirect_to return_to
  end

  subject do |resource_owner, application|
    # Example implementation:
    # resource_owner.id

    # or if you need pairwise subject identifier, implement like below:
    # Digest::SHA256.hexdigest("#{resource_owner.id}#{URI.parse(application.redirect_uri).host}#{'your_secret_salt'}")

    resource_owner.id
  end

  end_session_endpoint do
    authority = Authority.find_by_domain(request.host)
    authority.logout_url
  end

  # Protocol to use when generating URIs for the discovery endpoint,
  # for example if you also use HTTPS in development
  # protocol do
  #   :https
  # end

  # Expiration time on or after which the ID Token MUST NOT be accepted for processing. (default 120 seconds).
  # expiration 600

  claims do
    claim :sub do |resource_owner|
      resource_owner.id
    end

    claim :email do |resource_owner|
      resource_owner.email
    end

    claim :full_name do |resource_owner|
      resource_owner.name
    end

    claim :given_name do |resource_owner|
      resource_owner.first_name
    end

    claim :family_name do |resource_owner|
      resource_owner.last_name
    end

    claim :nickname do |resource_owner|
      resource_owner.nickname
    end

    claim :phone_number do |resource_owner|
      resource_owner.phone
    end

    claim :preferred_username do |resource_owner|
      resource_owner.login_name || resource_owner.email
    end
  end
end
