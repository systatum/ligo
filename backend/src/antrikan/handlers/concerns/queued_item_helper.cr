module Antrikan
  module QueuedItemHelper
    @queued_item : QueuedItem?
    @queued_item_by_id : QueuedItem?
    @schema : QueuedItemSchema?
    @update_schema : QueuedItemUpdateSchema?

    def authorize_queued_item_manipulation_request!(queue : Queue)
      raise Auth::AuthorizationError.new unless current_user

      queue_org_id = queue.channel!.space!.owner!.organization_id
      unless current_user!.organization_id == queue_org_id
        raise Auth::AuthorizationError.new
      end
    end

    def authorize_queued_item_access!(queued_item : QueuedItem)
      raise Auth::AuthorizationError.new unless current_user

      org_id = queued_item.queue!.channel!.space!.owner!.organization_id
      raise Auth::AuthorizationError.new unless current_user!.organization_id == org_id
    end

    private def queued_item
      @queued_item ||= QueuedItem.get_by_slug!(params["queued_item_slug"].to_s)
    end

    private def queued_item_by_id
      @queued_item_by_id ||= QueuedItem.unscoped.get!(id: params["queued_item_id"].to_s)
    end

    private def schema
      @schema ||= QueuedItemSchema.new(request.data)
    end

    private def update_schema
      @update_schema ||= QueuedItemUpdateSchema.new(request.data)
    end
  end
end
