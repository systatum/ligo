module Antrikan
  class QueueCreateHandler < RequestHandler
    include ChannelHelper

    protect_from_forgery false
    http_method_names :post

    def post : Marten::HTTP::Response
      rate_limit(name: "antrikan:queue-create") do |keys|
        queuer_id = queuer_id_for_throttle
        keys << queuer_id.not_nil! if queuer_id
      end

      result = Queue::CreatorService.new(channel, request.data).run

      if result.success?
        json QueueSerializer.serialize(result.data.not_nil!), status: 201
      else
        render_invalid_payload(result.errors)
      end
    end

    private def queuer_id_for_throttle : String?
      raw = request.data["queuer_id"]?
      return nil if raw.nil?

      case raw
      when String
        raw
      when JSON::Any
        raw.as_s?
      else
        nil
      end
    end
  end
end
