class RemovePreviousRefreshTokenFromOauthAccessTokens < ActiveRecord::Migration[8.1]
  # Dropping `previous_refresh_token` switches Doorkeeper's refresh flow
  # from deferred revocation to immediate revocation: once a refresh token
  # is used, it's marked revoked before the new pair is returned, so the
  # same refresh token can't mint another set of tokens.
  #
  # Trade-off: there is no longer a grace window for the client to retry
  # if it lost the response to the new pair. The accepted behaviour is to
  # re-authenticate, in line with RFC 6819 §5.2.2.3.
  def up
    remove_column :oauth_access_tokens, :previous_refresh_token
  end

  def down
    add_column :oauth_access_tokens, :previous_refresh_token, :string, null: false, default: ""
  end
end
