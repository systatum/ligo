module Antrikan
  class QueuedItemCreateHandler < RequestHandler
    include QueueHelper

    protect_from_forgery false
    http_method_names :post

    def post : Marten::HTTP::Response
      result = QueuedItem::CreatorService.new(queue, request.data).run

      if result.success?
        json QueuedItemSerializer.serialize(result.data.not_nil!), status: 201
      else
        render_invalid_payload(result.errors)
      end
    end
  end
end
