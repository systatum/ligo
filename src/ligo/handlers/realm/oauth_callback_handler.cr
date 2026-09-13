module Ligo
  class OAuthCallbackHandler < RequestHandler
    include OAuthFacility

    protect_from_forgery false
    http_method_names :get

    before_dispatch :validate_state

    def get
      MultiAuth.config(provider, realm.app_id!, realm.app_secret!)

      result = OAuthTokenAuthenticatorService.new(
        realm: realm,
        multi_auth: multi_auth,
        code: request.query_params["code"]?.to_s
      ).run

      if result.success?
        json UserTokenSerializer.serialize(result.data.not_nil!), status: 200
      else
        render_invalid_payload(result.errors)
      end
    end

    private def validate_state
      state = request.query_params["state"]?
      return if state.nil? || state.empty?
      render_error(403, ["State token is invalid"]) unless SignedToken.valid?(state)
    end
  end
end
