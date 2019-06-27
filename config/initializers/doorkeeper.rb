require 'set'

Doorkeeper.configure do
  orm :rethinkdb

  # This block will be called to check whether the
  # resource owner is authenticated or not
  resource_owner_authenticator do |routes|
    # We use cookies signed instead of session as then we can limit
    # the cookie to particular paths (i.e. /auth)
    begin
      cookie = cookies.encrypted[:user]
      user = User.find?(cookie[:id]) if cookie
      user || redirect_to('/login_required.html')
    rescue TypeError
      cookies.delete(:user,   path: '/auth')
      cookies.delete(:social, path: '/auth')
      cookies.delete(:continue, path: '/auth')
      redirect_to('/login_required.html')
    end
  end

  # restrict the access to the web interface for adding
  # oauth authorized applications
  if Rails.env.production?
    admin_authenticator do |routes|
      admin = begin
        user = User.find(cookies.encrypted[:user][:id])
        user.sys_admin == true
      rescue
        false
      end
      render nothing: true, status: :not_found unless admin
    end
  else
    admin_authenticator do |routes|
      true
    end
  end

  # Skip authorization only if the app is owned by us
  if Rails.env.production?
    skip_authorization do |resource_owner, client|
      client.application.skip_authorization
    end
  else
    skip_authorization do |resource_owner, client|
      true
    end
  end

  # username and password authentication for local auth
  resource_owner_from_credentials do |routes|
    user = User.find_by_email(Authority.find_by_domain(request.host)&.id, params[:username])
    if user && user.authenticate(params[:password])
      user
    end
  end

  # Issue access tokens with refresh token (disabled by default)
  access_token_expires_in 2.weeks.to_i
  use_refresh_token

  # Define access token scopes for your provider
  # For more information go to https://github.com/applicake/doorkeeper/wiki/Using-Scopes
  default_scopes  :public
  optional_scopes :admin

  access_token_generator '::Doorkeeper::JWT'

  force_ssl_in_redirect_uri false
  grant_flows %w(authorization_code client_credentials implicit password)
end

Doorkeeper::JWT.configure do
  token_payload do |opts|
    user = User.find(opts[:resource_owner_id])

    {
      iss: 'ACAE',
      iat: Time.current.utc.to_i,

      # @see JWT reserved claims - https://tools.ietf.org/html/draft-jones-json-web-token-07#page-7
      jti: SecureRandom.uuid,

      user: {
        id: user.id,
        email: user.email,
        admin: user.sys_admin,
        support: user.support,
      }
    }
  end

  # Use the application secret specified in the access grant token. Defaults to
  # `false`. If you specify `use_application_secret true`, both `secret_key` and
  # `secret_key_path` will be ignored.
  use_application_secret true

  # Set the encryption secret. This would be shared with any other applications
  # that should be able to read the payload of the token. Defaults to "secret".
  secret_key (ENV['JWT_SECRET'] || '9Bv6g5HJT5IN2mHehGF17pyorvd4gGfmXzrbEvg4VlZq411ECqXgjHtLJy3vb8Zc07Ao3HFdZ42kDsNZdLZbz07GH9vv2XcQh16Ua8JpuxD8HigR0VzJ1cEJLt+pyD0atOrWf9vfiRoPThXK69AOv9aSVmXagccwzTJ7WDm383k')

  # Specify encryption type (https://github.com/progrium/ruby-jwt)
  encryption_method :hs512
end
