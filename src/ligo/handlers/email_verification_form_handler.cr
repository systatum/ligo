module Ligo
  class EmailVerificationFormHandler < RequestHandler
    protect_from_forgery false
    http_method_names :get

    before_dispatch :require_user

    def get
      user_hashed = request.query_params["user"].to_s
      redirection_uri = request.query_params["redirectionUri"]?.presence

      user = User.filter_by_hashed_id(user_hashed).first?
      if user.nil?
        return render_error 400, ["User not found"]
      end

      if user.is_email_address_verified?
        if redirection_uri
          return redirect redirection_uri
        else
          return respond "<h1>Email address verified</h1>"
        end
      end

      if user.email_verification_token_expired_at && Time.utc > user.email_verification_token_expired_at.not_nil!
        User::EmailVerificationSendJob.async.perform(user.email!, redirection_uri, nil)
        return respond "<h1>Verification link expired</h1><p>A new verification email has been sent.</p>"
      end

      render "email_verification/form.html", {user_hashed: user_hashed, redirection_uri: redirection_uri}
    end

    private def require_user
      user_h = request.query_params["user"]?
      return if user_h.presence

      render_error 400, ["Missing user identifier"]
    end
  end
end
