# encoding: UTF-8

require 'set'
require 'base64'
require 'securerandom'
require 'doorkeeper'
require 'doorkeeper/jwt'
require 'doorkeeper-rethinkdb'

Doorkeeper.configure do
  orm :rethinkdb
  hash_token_secrets

  # This block will be called to check whether the
  # resource owner is authenticated or not
  resource_owner_authenticator do |routes|
    # We use cookies signed instead of session as then we can limit
    # the cookie to particular paths (i.e. /auth)
    begin
      cookie = cookies.encrypted[:user]
      user = User.find?(cookie['id']) if cookie && Time.now.to_i < cookie['expires']
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
        user = User.find(cookies.encrypted[:user]['id'])
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
    created_at = opts[:created_at].to_i
    expires = created_at + opts[:expires_in]

    # Generate permissions bitflags
    permissions = 0
    permissions |= 1 if user.support
    permissions |= 2 if user.sys_admin

    {
      iss: 'POS',
      iat: created_at,

      # Match the access token expiry time
      exp: expires,

      # @see JWT reserved claims - https://tools.ietf.org/html/draft-jones-json-web-token-07#page-7
      # Currently we only use this add some randomness to the token
      # This avoids database clashes when refreshed straight away
      jti: SecureRandom.uuid,

      # The domain on which the token is valid (Audience)
      # TODO:: change this to `authority.id`
      aud: user.authority.domain,
      scope: Array(opts[:scopes]),

      # The subject of the token (User)
      sub: user.id,

      # User metadata
      u: {
        # Name
        n: user.name,
        # Email
        e: user.email,
        # Permissions bitflags
        p: permissions,
        # Roles
        r: user.groups
      }
    }
  end

  # Set the encryption secret. This would be shared with any other applications
  # that should be able to read the payload of the token. Defaults to "secret".
  key = ENV['JWT_SECRET']
  key = key.try { |k| Base64.decode64(k) } || <<~KEY
    -----BEGIN RSA PRIVATE KEY-----
    MIIEpAIBAAKCAQEAt01C9NBQrA6Y7wyIZtsyur191SwSL3MjR58RIjZ5SEbSyzMG
    3r9v12qka4UtpB2FmON2vwn0fl/7i3Jgh1Xth/s+TqgYXMebdd123wodrbex5pi3
    Q7PbQFT6hhNpnsjBh9SubTf+IeTIFeXUyqtqcDBmEoT5GxU6O+Wuch2GtbfEAmaD
    roy+uyB7P5DxpKLEx8nlVYgpx5g2mx2LufHvykVnx4bFzLezU93SIEW6yjPwUmv9
    R+wDM/AOg60dIf3hCh1DO+h22aKT8D8ysuFodpLTKCToI/AbK4IYOOgyGHZ7xizX
    HYXZdsqX5/zBFXu/NOVrSd/QBYYuCxbqe6tz4wIDAQABAoIBAQCEIRxXrmXIcMlK
    36TfR7h8paUz6Y2+SGew8/d8yvmH4Q2HzeNw41vyUvvsSVbKC0HHIIfzU3C7O+Lt
    9OeiBo2vTKrwNflBv9zPDHHoerlEBLsnNwQ7uEUeTWM9DHdBLwNaLzQApLD6q5iT
    OFW4NfIGpsydIt8R565PiNPDjIcTKwhbVdlsSbI87cLkQ9UuYIMRkvXSD1Q2cg3I
    VsC0SpE4zmfTe7YTZQ5yTxtsoLKPBXrSxhhGuhdayeN7A4YHFYVD39RuQ6/T2w2a
    W/0UaGOk8XWgydDpD5w9wiBdH2I4i6D35IynCcodc5JvmTajzJT+xj6aGjjvMSyq
    q5ZdwJ4JAoGBAOPdZgjbOCf3ONUoiZ5Qw/a4b4xJgMokgqZ5QGBF5GqV1Xsphmk1
    apYmgC7fmab/EOdycrQMS0am2FmtwX1f7gYgJoyWtK4TVkUc5rf+aoWi0ieIsegv
    rjhuiIAc12+vVIbegRgnq8mOI5icrwm6OkwdqHkwTt6VRYdJGEmu67n/AoGBAM3v
    RAd5uIjVwVDLXqaOpvF3pxWfl+cf6PJtAE5y+nbabeTmrw//fJMank3o7qCXkFZR
    F0OJ2tmENwV+LPM8Gy3So8YP2nkOz4bryaGrxQ4eMA+K9+RiACVaKv+tNx/NbyMS
    e9gg504u0cwa60XjM5KUKrmT3RXpY4YIfUPZ1J4dAoGAB6jalDOiSJ2j2G57acn3
    PGTowwN5g9IEXko3IsVWr0qIGZLExOaZxaBXsLutc5KhY9ZSCsFbCm3zWdhgZ7GA
    083i3dj3C970iHA3RToVJJbbj56ltFNd/OGiTwQpLcTsB3iVSFWVDbpsceXacG5F
    JWfd0O0RyaOk6a5IVbm+jMsCgYBglxAOfY4LSE8y6SCM+K3e5iNNZhymgHYPdwbE
    xPMrWgpfab/Evi2dBcgofM+oLU663bAOspMeoP/5qJPGxnNtC7ZbSMZNL6AxBVj+
    ZoW3uHsMXz8kNL8ixecTIxiO5xlwltPVrKExL46hsCKYFhfzcWGUx4DULTLMBCFU
    +M/cFQKBgQC+Ite962yJOnE+bjtSReOrvR9+I+YNGqt7vyRa2nGFxL7ZNIqHss5T
    VjaMgjzVJqqYozNT/74pE/b9UjYyMzO/EhrjUmcwriMMan/vTbYoBMYWvGoy536r
    4n455vizig2c4/sxU5yu9AF9Dv+qNsGCx2e9uUOTDUlHM9NXwxU9rQ==
    -----END RSA PRIVATE KEY-----
    KEY
  secret_key key

  # Specify encryption type (https://github.com/progrium/ruby-jwt)
  encryption_method :rs256
end
