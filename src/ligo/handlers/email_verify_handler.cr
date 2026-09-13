module Ligo
  class EmailVerifyHandler < RequestHandler
    protect_from_forgery false
    http_method_names :get

    before_dispatch :require_code

    def get
      code = request.query_params["code"].to_s
      user_hashed = request.query_params["user"]?.presence
      redirection_uri = request.query_params["redirectionUri"]?.presence

      result = User::EmailVerificationConfirmService.new(
        code: code,
        user_hashed: user_hashed,
      ).run

      if result.success?
        if redirection_uri
          redirect redirection_uri
        else
          respond "<h1>Email address verified</h1>"
        end
      else
        render_invalid_payload(result.errors)
      end
    end

    private def require_code
      code = request.query_params["code"]?
      return if code.presence

      render_error 400, ["Missing verification code"]
    end
  end
end
