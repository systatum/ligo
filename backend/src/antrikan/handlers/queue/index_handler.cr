module Antrikan
  class QueueIndexHandler < RequestHandler
    include ChannelHelper

    protect_from_forgery false
    http_method_names :get

    def get : Marten::HTTP::Response
      queues = channel.queues

      if raw = request.query_params["status"]?
        status = QueueStatus.parse(raw).value
        queues = queues.filter(status: status)
      end

      result = queues.map do |queue|
        QueueSerializer.soft_serialize(queue)
      end

      json({queues: result}, status: 200)
    end
  end
end
