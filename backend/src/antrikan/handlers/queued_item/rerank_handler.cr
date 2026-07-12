module Antrikan
  class QueuedItemRerankHandler < RequestHandler
    include QueueHelper
    include QueuedItemHelper

    protect_from_forgery false
    http_method_names :patch

    def patch : Marten::HTTP::Response
      authorize_queued_item_manipulation_request! queue

      result = QueuedItem::RerankService.new(queue, request.data).run

      if result.success?
        serialized = result.data.not_nil!.map { |qi| QueuedItemSerializer.soft_serialize(qi) }
        json({items: serialized}, status: 200)
      else
        render_invalid_payload(result.errors)
      end
    end
  end
end
