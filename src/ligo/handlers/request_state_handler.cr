module Ligo
  class RequestStateHandler < RequestHandler
    protect_from_forgery false
    http_method_names :get

    def get
      json({"state" => SignedToken.generate})
    end
  end
end
