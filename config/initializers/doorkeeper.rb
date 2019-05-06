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
    user = User.find_by_email(params[:authority], params[:username])
    if user && user.authenticate(params[:password])
      user
    end
  end

  # Issue access tokens with refresh token (disabled by default)
  access_token_expires_in 2.weeks
  use_refresh_token

  # Define access token scopes for your provider
  # For more information go to https://github.com/applicake/doorkeeper/wiki/Using-Scopes
  default_scopes  :public
  optional_scopes :admin

  force_ssl_in_redirect_uri false
  grant_flows %w(authorization_code client_credentials implicit password)
end
