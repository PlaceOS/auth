# PlaceOS Authentication

## ENV VARS

```bash
# If a sentry Data Source Name is configured
SENTRY_DSN=https://<key>@<organization>.ingest.sentry.io/<project>

# A shared secret for encrypting cookies
SECRET_KEY_BASE=84b04ea4259542f365

# JWT Private key
JWT_SECRET=Base64 Encoded RSA PRIVATE KEY

# Database name and host
RETHINKDB_DB=place_development
RETHINKDB_HOST=rethink
RETHINKDB_PORT=
RETHINKDB_USER=
RETHINKDB_PASSWORD=

# Rails environment to load
RAILS_ENV=production

# Disable forced SSL
COAUTH_NO_SSL=true

# Serving static files (true if set to anything)
RAILS_SERVE_STATIC_FILES=
```

## Authentication Flow

### Server to server

Use the Client Credentials flow

1. POST /auth/oauth/token

with body:

```yaml
{
  "grant_type"    : "password",
  "username"      : "user@example.com",
  "password"      : "sekret"
}
```

This will return

```yaml
{
  "access_token": "19adad999683f5b450c460726aa",
  "token_type": "bearer",
  "expires_in": 7200
}
```

### Native App Auth

1. Login
   * POST `/auth/signin` (or SSO login)
2. Request code with PKCE
   * GET `/auth/oauth/authorize?response_type=code&client_id=THE_ID&redirect_uri=THE_URL&scope=public&code_challenge=43_CHAR_CHALLENGE_CODE&code_challenge_method=S256`
   * returns a 303 redirect with location that includes: `?code=RETURNED_CODE`
3. Obtain token
   * POST `/auth/oauth/token?client_id=THE_ID&client_secret=THE_SECRET&code=RETURNED_CODE&grant_type=authorization_code&redirect_uri=THE_URL&code_verifier=SHA256(43_CHAR_CHALLENGE_CODE)`

This will return

 ```yaml
 {
   "access_token": "de6780bc506a0446309bd9362820ba8aed28aa506c71eedbe1c5c4f9dd350e54",
   "token_type": "Bearer",
   "expires_in": 7200,
   "refresh_token": "8257e65c97202ed1726cf9571600918f3bffb2544b26e00a61df9897668c33a1"
  }
 ```

## Revoking Refresh Tokens

```text
POST /auth/oauth/revoke?client_id=<client_id>&client_secret=<secret>
token=<refresh-token>
```
