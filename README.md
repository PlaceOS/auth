# PlaceOS Authentication

## ENV VARS

```
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

# File Uploads
DEFAULT_BUCKET=bucketname

# Default upload location (Amazon configured if S3_KEY set)
# recommended to configure via the Authority internals settings
S3_KEY=
S3_SECRET=
S3_REGION=ap-southeast-2

# Serving static files (true if set to anything)
RAILS_SERVE_STATIC_FILES=
```

## File upload configuration

Add these keys to the Authority internals config

* `"storage_bucket": "placeos_uploads_bucket"`

### Amazon

```
"storage": {
  "name": "AmazonS3",
  "access_id": "",
  "secret_key": "",
  "location": "us-east-1"
}
```

### Google

```
"storage": {
  "name": "GoogleCloudStorage",
  "access_id": "",
  "secret_key": "",
  "location": "na" # US or Europe
}
```

### Microsoft Azure

```
"storage": {
  "name": "MicrosoftAzure",
  "account_name": "",
  "access_key": "",
  # optional defaults to {account_name}.blob.core.windows.net
  "blob_host": nil
}
```

### OpenStack or RackSpace Cloud

```
"storage": {
  "name": "OpenStackSwift",
  "username": "admin:admin",
  "secret_key": "",
  "temp_url_key": "",
  "auth_url": "https://identity.api.rackspacecloud.com/v2.0/tokens",
  "auth_url": "https://swift.domain.com/auth/v1.0",
  # Location can be dallas, london, sydney, hong_kong for rackspace
  "location": "https://storage101.dfw1.clouddrive.com",
  "storage_url": "account_name",
  "scheme": "https" # or http (update the above urls)
}
```
