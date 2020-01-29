class ApplicationController < ActionController::Base
  SENTRY_CONFIGURED = !!ENV["SENTRY_DSN"]
  if SENTRY_CONFIGURED
    before_action :set_raven_context
  end

  private

  def set_raven_context
    user = cookies.encrypted[:user]
    Raven.user_context(id: user[:id] || user['id']) if user
    Raven.extra_context(url: request.original_url, remote_ip: request.remote_ip)
  end
end
