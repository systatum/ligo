module Antrikan
  class QueuedItemHistoryHandler < RequestHandler
    include QueuedItemHelper

    protect_from_forgery false
    http_method_names :get

    before_dispatch :authorize_history_access

    def get : Marten::HTTP::Response
      result = QueuedItem::HistoryRetrieverService.new(queued_item_by_id).run

      if result.success?
        json(result.data.not_nil!, status: 200)
      else
        render_invalid_payload(result.errors)
      end
    end

    private def authorize_history_access
      authorize_queued_item_access!(queued_item_by_id)
    end
  end
end
