module Auth
  class MyBioShowHandler < RequestHandler
    protect_from_forgery false
    http_method_names :get

    def get : Marten::HTTP::Response
      raise AuthorizationError.new unless current_user

      json UserSerializer.serialize(current_user!), status: 200
    end
  end
end
