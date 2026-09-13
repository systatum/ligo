require "json"
require "openssl/hmac"

module Ligo
  # Handles incoming registration webhooks from another deployment acting
  # as the IAM (identity source).
  class IamWebhookHandler < RequestHandler
    protect_from_forgery false
    http_method_names :post

    before_dispatch :validate_body_presence
    before_dispatch :validate_webhook_headers
    before_dispatch :ensure_secret_configured
    before_dispatch :verify_signature

    @raw_body : String?
    @timestamp : String?

    def post
      payload = JSON.parse(@raw_body.not_nil!)
      iam_identifier = payload["user_id"]?.try(&.as_s)
      return render_error(400, ["Missing user_id in payload"]) unless iam_identifier

      user_info = IamIdentifiable::UserInfo.new(
        given_name: payload["given_name"]?.try(&.as_s) || payload["email"]?.try(&.as_s) || "Unknown",
        family_name: payload["family_name"]?.try(&.as_s),
        email: payload["email"]?.try(&.as_s) || "",
        role: Role::GUEST
      )

      Ligo::User.find_or_create_by_iam_identifier(
        iam_identifier_primary: iam_identifier,
        user_info: user_info
      )

      head 204
    end

    private def validate_body_presence
      body = request.body
      return head 400 unless body.presence
      @raw_body = body
    end

    private def validate_webhook_headers
      @timestamp = request.headers["X-Systatum-Timestamp"]?
      return render_error(403, ["Missing webhook headers"]) unless @timestamp
      return render_error(403, ["Missing webhook headers"]) unless request.headers["X-Systatum-Signature"]?
    end

    private def ensure_secret_configured
      return render_error(403, ["Webhook secret not configured"]) if AppSettings.instance.ligo_webhook_secret.blank?
    end

    private def verify_signature
      secret = AppSettings.instance.ligo_webhook_secret
      expected = OpenSSL::HMAC.hexdigest(:sha256, secret, "#{@raw_body.not_nil!}#{@timestamp.not_nil!}")
      signature = request.headers["X-Systatum-Signature"]
      return render_error(403, ["Signature mismatch"]) unless Crypto::Subtle.constant_time_compare(expected, signature)
    end
  end
end
