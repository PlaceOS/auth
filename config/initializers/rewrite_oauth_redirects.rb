require_relative "../../app/middleware/rewrite_callback_request"
require_relative "../../app/middleware/rewrite_redirect_response"

# ensure we are not using the query param version of the oauth callbacks
Rails.application.config.middleware.insert_before 0, RewriteCallbackRequest
Rails.application.config.middleware.insert_before 0, RewriteRedirectResponse
