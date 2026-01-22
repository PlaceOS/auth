ARG RUBY_VER="4.0"
FROM ruby:$RUBY_VER-alpine AS build-env

# Build dependencies for native extensions
ARG BUILD_PACKAGES="build-base curl-dev libxml2-dev libxslt-dev zlib-dev libpq-dev yaml-dev git openssl-dev"
# Runtime packages needed for shared libraries
ARG RUNTIME_PACKAGES="tzdata libxml2 libxslt curl zlib libpq yaml"

ENV RAILS_ENV=production \
    RACK_ENV=production \
    BUNDLE_WITHOUT=development:test \
    BUNDLE_FROZEN=1 \
    BUNDLE_PATH=/app/vendor/bundle

RUN apk add --no-cache $BUILD_PACKAGES $RUNTIME_PACKAGES

# Set timezone
RUN cp /usr/share/zoneinfo/Australia/Sydney /etc/localtime && \
    echo "Australia/Sydney" > /etc/timezone

WORKDIR /app

# Copy Gemfiles for caching
COPY Gemfile* ./

# Tell Nokogiri to use system libraries
RUN bundle config build.nokogiri --use-system-libraries && \
    bundle config --global build.nokogiri --use-system-libraries

# Lower optimization to avoid compiler issues
ENV CFLAGS="-O0"

# Install bundler and gems
RUN gem install bundler --no-document && \
    bundle install -j$(nproc) --retry 3

# Copy application code
COPY . .

# Remove any existing vendor/bundle from repo (use fresh bundle install only)
RUN rm -rf vendor/bundle

# Reinstall gems fresh
RUN bundle install -j$(nproc) --retry 3

# Remove stale binstubs and regenerate for puma
RUN rm -rf bin/* && \
    bundle binstubs puma --force

# Clean up gem caches, build artifacts, docs, and tests
RUN rm -rf vendor/bundle/ruby/*/cache/*.gem && \
    find vendor/bundle/ruby/*/gems/ -name "*.c" -delete && \
    find vendor/bundle/ruby/*/gems/ -name "*.o" -delete && \
    find vendor/bundle/ruby/*/gems/ -name "*.h" -delete && \
    find vendor/bundle/ruby/*/gems/ -type d -name "spec" -exec rm -rf {} + 2>/dev/null || true && \
    find vendor/bundle/ruby/*/gems/ -mindepth 2 -type d -name "test" ! -path "*/rack-test-*/*" -exec rm -rf {} + 2>/dev/null || true && \
    find vendor/bundle/ruby/*/gems/ -type d -name "doc" -exec rm -rf {} + 2>/dev/null || true && \
    find vendor/bundle/ruby/*/gems/ -type d -name "examples" -exec rm -rf {} + 2>/dev/null || true && \
    find vendor/bundle/ruby/*/gems/ -name "*.md" -delete 2>/dev/null || true && \
    find vendor/bundle/ruby/*/gems/ -name "CHANGELOG*" -delete 2>/dev/null || true && \
    find vendor/bundle/ruby/*/gems/ -name "README*" -delete 2>/dev/null || true && \
    rm -rf tmp/pids spec test .git .github

##############################
# 2) FINAL STAGE
##############################
FROM ruby:$RUBY_VER-alpine

# Install package updates since image release
RUN apk update && apk --no-cache --quiet upgrade

ARG RUNTIME_PACKAGES="libxml2 libxslt zlib libpq yaml tzdata ca-certificates"
RUN apk add --no-cache $RUNTIME_PACKAGES

# Set timezone
RUN cp /usr/share/zoneinfo/Australia/Sydney /etc/localtime && \
    echo "Australia/Sydney" > /etc/timezone

ENV APP_DIR="/app"
WORKDIR $APP_DIR

ENV RAILS_ENV=production \
    RACK_ENV=production \
    BUNDLE_WITHOUT=development:test \
    BUNDLE_FROZEN=1 \
    BUNDLE_PATH=$APP_DIR/vendor/bundle

# Copy only the fully built app (with installed gems) from builder
COPY --from=build-env /app /app

# Create non-privileged user
ARG IMAGE_UID="10001"
RUN adduser -D -g "" -h "/nonexistent" -s "/sbin/nologin" -H -u "${IMAGE_UID}" appuser && \
    chown -R appuser:appuser $APP_DIR

# Strip unnecessary binaries and files from Alpine to minimize attack surface
# This must be done LAST since we need shell for RUN commands above
RUN rm -rf /usr/local/bin/erb \
           /usr/local/bin/gem \
           /usr/local/bin/irb \
           /usr/local/bin/racc \
           /usr/local/bin/rdoc \
           /usr/local/bin/ri \
           /usr/local/lib/ruby/gems/*/gems/rdoc-* \
           /usr/local/lib/ruby/gems/*/gems/irb-* \
           /usr/local/lib/ruby/gems/*/gems/rbs-* \
           /usr/local/lib/ruby/gems/*/gems/debug-* \
           /usr/local/lib/ruby/gems/*/gems/racc-* \
           /usr/local/lib/ruby/gems/*/specifications/rdoc-* \
           /usr/local/lib/ruby/gems/*/specifications/irb-* \
           /usr/local/lib/ruby/gems/*/specifications/rbs-* \
           /usr/local/lib/ruby/gems/*/specifications/debug-* \
           /usr/local/lib/ruby/gems/*/specifications/racc-* \
           /usr/local/lib/ruby/*/rdoc* \
           /usr/local/lib/ruby/*/irb* \
           /usr/local/share/ri \
           /usr/local/lib/ruby/gems/*/doc \
           /usr/local/lib/ruby/gems/*/cache \
    && rm -rf /sbin/apk /usr/bin/wget /usr/bin/ssl_client /usr/bin/curl \
              /lib/apk /etc/apk /var/cache/apk

USER appuser
EXPOSE 8080

# Healthcheck using ruby since wget is removed - raises on non-2xx response
HEALTHCHECK CMD ["/usr/local/bin/ruby", "-e", "require 'net/http'; res = Net::HTTP.get_response(URI('http://127.0.0.1:8080/auth/authority?health=true')); exit(1) unless res.is_a?(Net::HTTPSuccess)"]

ENTRYPOINT ["./bin/puma", "-b", "tcp://0.0.0.0:8080"]
