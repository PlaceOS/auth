require "active_support/core_ext/integer/time"

# Remove the locks from the logger
require "mono_logger"
require "lograge"
require "omniauth"
require "socket"

# Replace the default JSON parser
require "json"

UDP_LOG_HOST = ENV["UDP_LOG_HOST"] || ENV["LOGSTASH_HOST"]
UDP_LOG_PORT = ENV["UDP_LOG_PORT"] || ENV["LOGSTASH_PORT"]

# So we can log to two places at once (STDOUT and Socket)
class MultiIO
  def self.delegate_all
    IO.methods.each do |m|
      define_method(m) do |*args|
        ret = nil
        @targets.each { |t| ret = t.__send__(m, *args) }
        ret
      end
    end
  end

  def initialize(*targets)
    @targets = targets
    MultiIO.delegate_all
  end
end

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # disable host blocking
  config.hosts.clear

  config.active_record.migration_error = false

  # Code is not reloaded between requests.
  config.cache_classes = true

  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both threaded web servers
  # and those relying on copy on write to perform better.
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = true

  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Ensures that a master key has been made available in either ENV["RAILS_MASTER_KEY"]
  # or in config/master.key. This key is used to decrypt credentials (and other encrypted files).
  # config.require_master_key = true

  # Disable serving static files from the `/public` folder by default since
  # Apache or NGINX already handles this.
  config.public_file_server.enabled = ENV["RAILS_SERVE_STATIC_FILES"].present?

  # Compress CSS using a preprocessor.
  # config.assets.css_compressor = :sass

  # Do not fallback to assets pipeline if a precompiled asset is missed.
  # config.assets.compile = false

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.asset_host = "http://assets.example.com"

  # Specifies the header that your server uses for sending files.
  # config.action_dispatch.x_sendfile_header = "X-Sendfile" # for Apache
  # config.action_dispatch.x_sendfile_header = "X-Accel-Redirect" # for NGINX

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = :local

  # Mount Action Cable outside main process or domain.
  # config.action_cable.mount_path = nil
  # config.action_cable.url = "wss://example.com/cable"
  # config.action_cable.allowed_request_origins = [ "http://example.com", /http:\/\/example.*/ ]

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  # config.force_ssl = true

  # Include generic and useful information about system operation, but avoid logging too much
  # information to avoid inadvertent exposure of personally identifiable information (PII).
  config.log_level = :info

  # Prepend all log lines with the following tags.
  config.log_tags = [ :request_id ]

  # Use a different cache store in production.
  # config.cache_store = :mem_cache_store

  # Use a real queuing backend for Active Job (and separate queues per environment).
  # config.active_job.queue_adapter     = :resque
  # config.active_job.queue_name_prefix = "placeos_auth_production"

  config.action_mailer.perform_caching = false

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  # config.action_mailer.raise_delivery_errors = false

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Don't log any deprecations.
  config.active_support.report_deprecations = false

  # Use default logging formatter so that PID and timestamp are not suppressed.
  config.log_formatter = ::Logger::Formatter.new

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # Custom logging
  $stdout.sync = true
  $stderr.sync = true

  # Output to both UDP and STDOUT
  outputs = [$stdout]
  if UDP_LOG_HOST && UDP_LOG_PORT
    socket = UDPSocket.new
    socket.connect(UDP_LOG_HOST, UDP_LOG_PORT.to_i)
    outputs << socket
  end

  # Only output the message (in logstash format)
  logger = MonoLogger.new(MultiIO.new(*outputs))
  logger.level = MonoLogger::INFO
  logger.formatter = proc { |_severity, _datetime, _progname, msg| "#{msg}\n" }

  # configure lograge and logstash
  config.logger = logger
  config.lograge.logger = logger
  Lograge.logger = logger
  OmniAuth.config.logger = logger
  config.lograge.enabled = true
  config.lograge.base_controller_class = ["ActionController::API", "ActionController::Base"]
  config.lograge.custom_payload do |controller|
    user = controller.respond_to?(:doorkeeper_token, true) ? controller.__send__(:doorkeeper_token) : "anonymous"
    {
      user_id: (user || "anonymous")
    }
  end

  config.lograge.formatter = Lograge::Formatters::Logstash.new

  # Ensures only our lograge error is logged
  # standard:disable Lint/ConstantDefinitionInBlock
  module ActionDispatch
    class DebugExceptions
      def log_error(request, wrapper)
      end
    end
  end
  # standard:enable Lint/ConstantDefinitionInBlock
end
