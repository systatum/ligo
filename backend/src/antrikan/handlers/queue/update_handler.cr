module Antrikan
  class QueueUpdateHandler < RequestHandler
    include QueueHelper

    protect_from_forgery false
    http_method_names :patch

    def patch : Marten::HTTP::Response
      result = Queue::UpdaterService.new(queue, request.data).run

      if result.success?
        json QueueSerializer.serialize(result.data.not_nil!), status: 200
      else
        render_invalid_payload(result.errors)
      end
    end
  end
end
