module Antrikan
  class QueuerShowHandler < RequestHandler
    include QueuerHelper

    protect_from_forgery false
    http_method_names :get

    def get : Marten::HTTP::Response
      json QueuerSerializer.serialize(queuer), status: 200
    end
  end
end
