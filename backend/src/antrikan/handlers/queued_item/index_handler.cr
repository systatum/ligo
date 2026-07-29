module Antrikan
  class QueuedItemIndexHandler < RequestHandler
    include QueueHelper

    protect_from_forgery false
    http_method_names :get

    def get : Marten::HTTP::Response
      items = queue.queued_items.order(:rank, :created_at)

      result = items.map do |qi|
        QueuedItemSerializer.soft_serialize(qi)
      end

      json(result, status: 200)
    end
  end
end
