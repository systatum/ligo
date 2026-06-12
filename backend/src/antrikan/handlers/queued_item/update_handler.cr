module Antrikan
  class QueuedItemUpdateHandler < RequestHandler
    include QueueHelper
    include QueuedItemHelper

    protect_from_forgery false
    http_method_names :patch

    def patch : Marten::HTTP::Response
      authorize_queued_item_manipulation_request! queue

      result = QueuedItem::UpdaterService.new(queued_item_by_queue(queue), request.data).run

      if result.success?
        json QueuedItemSerializer.serialize(result.data.not_nil!), status: 200
      else
        render_invalid_payload(result.errors)
      end
    end
  end
end
