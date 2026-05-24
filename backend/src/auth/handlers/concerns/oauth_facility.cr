module Auth
  module OAuthFacility
    EXPLICIT_PROVIDER_SCOPES = {
      "facebook" => "email",
    } of String => String

    @multi_auth : MultiAuth::Engine?

    def multi_auth
      @multi_auth ||= MultiAuth.make(provider, redirect_uri)
    end

    def scope
      EXPLICIT_PROVIDER_SCOPES[provider.downcase]?
    end

    private def provider
      params["provider"].to_s
    end

    private def redirect_uri
      "#{request.scheme}://#{request.host}#{reverse("auth:api_oauth_callback", provider: provider)}"
    end
  end
end
