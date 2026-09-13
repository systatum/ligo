module OAuthFacility
  EXPLICIT_PROVIDER_SCOPES = {
    "facebook" => "email",
  } of String => String

  @multi_auth : MultiAuth::Engine?
  @realm : Ligo::Realm?

  def multi_auth
    @multi_auth ||= MultiAuth.make(provider, redirect_uri)
  end

  def scope
    EXPLICIT_PROVIDER_SCOPES[provider.downcase]?
  end

  private def realm
    @realm ||= Ligo::Realm.get!(id: params["realm_id"].to_s)
  end

  private def provider
    params["provider"].to_s
  end

  private def redirect_uri
    "#{request.scheme}://#{request.host}#{reverse("realm_oauth_callback", realm_id: realm.id!, provider: provider)}"
  end
end
