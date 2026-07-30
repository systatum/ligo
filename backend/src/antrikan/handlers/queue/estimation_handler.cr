module Antrikan
  class QueueEstimationHandler < RequestHandler
    include QueueHelper

    protect_from_forgery false
    http_method_names :get

    def get : Marten::HTTP::Response
      result = Queue::EstimatorService.new(queue).run

      estimations = result.data.not_nil!.map do |estimation|
        {channel_id: estimation.channel.hashed_id, items_ahead: estimation.items_ahead}
      end

      json estimations, status: 200
    end
  end
end
