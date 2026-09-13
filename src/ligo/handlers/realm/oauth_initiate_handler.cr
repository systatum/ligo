module Ligo
  class OAuthInitiateHandler < RequestHandler
    include OAuthFacility

    protect_from_forgery false
    http_method_names :get

    def get
      MultiAuth.config(provider, realm.app_id!, realm.app_secret!)

      redirect multi_auth.authorize_uri(scope: scope)
    end
  end
end
