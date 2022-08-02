# Rewrite location header from:
# https://org.b2clogin.com/org.onmicrosoft.com/B2C_1_singup_signin/oauth2/v2.0/authorize?client_id=123456-qwerty&redirect_uri=https%3A%2F%2Forg-dev.aca.im%2Fauth%2Foauth2%2Fcallback%3Fid%3Doauth_strat-QWERTY&response_type=code&scope=openid+offline_access&state=8765
# to:
# https://org.b2clogin.com/org.onmicrosoft.com/B2C_1_singup_signin/oauth2/v2.0/authorize?client_id=123456-qwerty&redirect_uri=https%3A%2F%2Forg-dev.aca.im%2Fauth%2Foauth2%2Fcallback%2Foauth_strat-QWERTY&response_type=code&scope=openid+offline_access&state=8765
# if domain is: b2clogin.com
#
# That is replace "%3Fid%3D" with "%2F"
# and "?id=" with "/"
#
class RewriteRedirectResponse
  def initialize(app)
    @app = app
  end

  def call(env)
    status, headers, body = @app.call(env)

    if (location = headers.fetch("location", nil)) && (uri = URI.parse(location)) && uri.host =~ /\.b2clogin\.com$/
      uri.query = uri.query.sub("%3Fid%3D", "%2F")
      uri.query = uri.query.sub("?id=", "/")

      # logger.debug "Rewrite location header from: #{headers["location"]} to: #{uri}"

      headers["location"] = uri
    end

    [status, headers, body]
  end
end
