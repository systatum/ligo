module Ligo
  class RequestEmailVerificationHandler < RequestHandler
    protect_from_forgery false
    http_method_names :get

    before_dispatch :require_email

    def get
      email = request.query_params["email"].to_s
      redirection_uri = request.query_params["redirectionUri"]?.presence
      expired_at_iso = request.query_params["expiredAt"]?.presence

      User::EmailVerificationSendJob.async.perform(email, redirection_uri, expired_at_iso)

      render_no_content
    end

    private def require_email
      email = request.query_params["email"]?
      return if email.presence

      render_error 400, ["Email is required"]
    end
  end
end
