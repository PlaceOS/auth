# Sample Auth code

## Crystal lang Client Credentials flow

```crystal

require "oauth2"

client_id = "0149d1efb4f4efb5b6f80e907da979c7"
client_secret = "216de7d1f963592845d7d502efa3e88b614479f08c594f775103c084e008fc0e371e276e93a5898f28f413bb3f1e12a0"
redirect_uri = "http://localhost:8080/backoffice/oauth-resp.html"

# Create oauth client, optionally pass custom URIs if needed,
# if the authorize or token URIs are not the standard ones
# (they can also be absolute URLs)
oauth2_client = OAuth2::Client.new("localhost:8080", client_id, client_secret,
  redirect_uri: redirect_uri,
    authorize_uri: "http://localhost:8080/auth/oauth/authorize",
    token_uri: "http://localhost:8080/auth/oauth/token")


token = oauth2_client.get_access_token_using_resource_owner_credentials(
  "support@aca.im",
  "development",
  "public"
).as(OAuth2::AccessToken::Bearer)

```


## Crystal lang refresh token

```crystal

require "oauth2"

client_id = "0149d1efb4f4efb5b6f80e907da979c7"
client_secret = "216de7d1f963592845d7d502efa3e88b614479f08c594f775103c084e008fc0e371e276e93a5898f28f413bb3f1e12a0"
redirect_uri = "http://localhost:8080/backoffice/oauth-resp.html"

# Create oauth client, optionally pass custom URIs if needed,
# if the authorize or token URIs are not the standard ones
# (they can also be absolute URLs)
oauth2_client = OAuth2::Client.new("localhost:8080", client_id, client_secret,
  redirect_uri: redirect_uri,
    authorize_uri: "http://localhost:8080/auth/oauth/authorize",
    token_uri: "http://localhost:8080/auth/oauth/token")

# Build an authorize URI
authorize_uri = oauth2_client.get_authorize_uri

# Use the token to authenticate an HTTP::Client
client = HTTP::Client.new("localhost", 8080)

# And do requests as usual
response = client.get authorize_uri, HTTP::Headers{"Cookie" => "user=y1GTR1Xf7ZuhoYGYtOuQVyY8hwUhbwnRoh%2FEuuB%2F7frquxI14zpCUqQqJZs%3D--QxluRWU9NngkNOA3--bTqBdZlpiGoOsBtRVV3Tnw%3D%3D"}


# Redirect the user to `authorize_uri`...
#
# ...
#
# When http://some.callback is hit, once the user authorized the access,
# we resume our logic to finally get an access token. The callback URL
# should receive an `authorization_code` parameter that we need to use.
loc = response.headers["Location"]
authorization_code = loc.split("code=")[1]

# Get the access token
access_token = oauth2_client.get_access_token_using_authorization_code(authorization_code)

# Probably save the access token for reuse... This can be done
# with `to_json` and `from_json`.

sleep 2

# If the token expires, we can refresh it
new_access_token = oauth2_client.get_access_token_using_refresh_token(access_token.refresh_token)

sleep 2

new_access_token = oauth2_client.get_access_token_using_refresh_token(access_token.refresh_token)


```


## Refresh token using PKCE Flow

```crystal

require "oauth2"

client_id = "0149d1efb4f4efb5b6f80e907da979c7"
client_secret = "216de7d1f963592845d7d502efa3e88b614479f08c594f775103c084e008fc0e371e276e93a5898f28f413bb3f1e12a0"
redirect_uri = "http://localhost:8080/backoffice/oauth-resp.html"

auth_cookie = "user=y1GTR1Xf7ZuhoYGYtOuQVyY8hwUhbwnRoh%2FEuuB%2F7frquxI14zpCUqQqJZs%3D--QxluRWU9NngkNOA3--bTqBdZlpiGoOsBtRVV3Tnw%3D%3D"

challenge = "43_CHAR_CHALLENGE_CODE43_CHAR_CHALLENGE_CODEsdssdsdsdsd"
challenge_verify = Base64.urlsafe_encode(OpenSSL::Digest.new("SHA256").update(challenge).digest).split("=")[0]

authorize_uri = "http://localhost:8080/auth/oauth/authorize?response_type=code&code_challenge_method=S256&code_challenge=#{challenge_verify}&scope=public&client_id=#{client_id}&redirect_uri=#{redirect_uri}"
response = HTTP::Client.get authorize_uri, HTTP::Headers{"Cookie" => auth_cookie}

loc = response.headers["Location"]
code = loc.split("code=")[1]


token_uri = "http://localhost:8080/auth/oauth/token?grant_type=authorization_code&code=#{code}&code_verifier=#{challenge}&client_id=#{client_id}&client_secret=#{client_secret}&redirect_uri=#{redirect_uri}"
token_resp = HTTP::Client.post token_uri


```

## Checking a token is valid

```crystal

# Create an HTTP::Client
client = HTTP::Client.new("localhost", 8080)

# Prepare it for using OAuth2 authentication
access_token.authenticate(client)

# NOTE:: can't inspect a token using a token
response = client.get("/auth/oauth/introspect?token=#{access_token.access_token}")

```
