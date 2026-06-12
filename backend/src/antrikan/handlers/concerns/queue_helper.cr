module Antrikan
  module QueueHelper
    @queue : Queue?
    @schema : QueueSchema?
    @update_schema : QueueUpdateSchema?

    private def queue
      @queue ||= Queue
        .filter_by_slug(params["queue_slug"].to_s)
        .get!
    end

    private def queue_even_if_deleted
      @queue ||= Queue
        .filter_by_slug(params["queue_slug"].to_s, unscoped: true)
        .get!
    end

    private def schema
      @schema ||= QueueSchema.new(request.data)
    end

    private def update_schema
      @update_schema ||= QueueUpdateSchema.new(request.data)
    end
  end
end
