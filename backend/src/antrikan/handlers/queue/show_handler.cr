module Antrikan
  class QueueShowHandler < RequestHandler
    include QueueHelper

    protect_from_forgery false
    http_method_names :get

    def get : Marten::HTTP::Response
      json QueueSerializer.serialize(queue), status: 200
    end
  end
end
