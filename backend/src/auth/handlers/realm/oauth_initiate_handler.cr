module Auth
  class OAuthInitiateHandler < RequestHandler
    include IamOnly
    include OAuthFacility

    protect_from_forgery false
    http_method_names :get

    def get
      MultiAuth.config(provider, realm.app_id!, realm.app_secret!)

      # latest multi_auth version (v1.1.1) is apparently missing the state param...
      # state = SignedToken.generate
      redirect multi_auth.authorize_uri(scope: scope)
    end
  end
end
