# Rewrite from:
# /auth/oauth2/callback/oauth_strat-QWERTY?code=1234&state=8765
# to:
# /auth/oauth2/callback?id=oauth_strat-QWERTY&?code=1234&state=8765
#
# That is replace "?id=" with "/"
#
class RewriteCallbackRequest
  def initialize(app)
    @app = app
  end

  def call(env)
    if (regex = env["REQUEST_PATH"].match(/^\/auth\/oauth2\/callback\/(oauth_strat-\w+)$/))
      strategy = regex.captures.last

      query = if env["QUERY_STRING"].empty?
        "id=#{strategy}"
      else
        "id=#{strategy}&#{env["QUERY_STRING"]}"
      end

      @app.logger.debug "Rewrite request from: #{REQUEST_URI} to: /auth/oauth2/callback?#{query}"

      @app.call(env.merge({
        "REQUEST_PATH" => "/auth/oauth2/callback",
        "PATH_INFO" => "/auth/oauth2/callback",
        "QUERY_STRING" => query,
        "REQUEST_URI" => "/auth/oauth2/callback?#{query}"
      }))
    else
      @app.call(env)
    end
  end
end
