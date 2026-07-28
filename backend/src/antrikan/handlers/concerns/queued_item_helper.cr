module Antrikan
  module QueuedItemHelper
    @queued_item : QueuedItem?
    @scoped_queued_item : QueuedItem?
    @schema : QueuedItemSchema?
    @update_schema : QueuedItemUpdateSchema?

    def authorize_queued_item_manipulation_request!(queue : Queue)
      raise Auth::AuthorizationError.new unless current_user

      queue_org_id = queue.space!.manager!.organization_id
      raise Auth::AuthorizationError.new unless current_user!.organization_id == queue_org_id
    end

    private def queued_item
      @queued_item ||= QueuedItem.get_by_slug!(params["queued_item_slug"].to_s)
    end

    private def queued_item_by_queue(queue : Queue)
      @scoped_queued_item ||= queue.queued_items
        .filter(slug: params["queued_item_slug"].to_s)
        .get!
    end

    private def schema
      @schema ||= QueuedItemSchema.new(request.data)
    end

    private def update_schema
      @update_schema ||= QueuedItemUpdateSchema.new(request.data)
    end
  end
end
