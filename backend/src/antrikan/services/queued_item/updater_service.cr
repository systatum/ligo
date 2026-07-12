module Antrikan
  class QueuedItem::UpdaterService < BaseService(Array(QueuedItem))
    def initialize(@organization_id : String, @data : Marten::HTTP::Params::Data)
    end

    def run : ServiceResult(Array(QueuedItem))
      return failure(schema.errors) unless schema.valid?

      items_payload = Array(QueuedItemUpdatePayload).from_json(schema.items!.to_json)
      return failure(:items, "must be a non-empty array") if items_payload.empty?

      queue_items = QueuedItem.unscoped.filter(id__in: items_payload.map(&.id)).to_a
      unless queue_items.size == items_payload.size
        return failure(:items, "Some items not found")
      end

      authorize_items!(queue_items)

      id_to_queue_item = queue_items.index_by { |qi| qi.id.to_s }
      updated = [] of QueuedItem

      items_payload.each do |payload|
        qi = id_to_queue_item[payload.id]
        update_fields(qi, payload)
        publish_queued_item_updated(qi)
        updated << qi
      end

      success(updated)
    rescue ex : AASM::AASMException
      failure(:status, ex.message || "Invalid status transition")
    rescue ex : Marten::DB::Errors::InvalidRecord
      failure(ex.record.errors)
    rescue ex : JSON::SerializableError
      failure(:items, ex.message || "Invalid items format")
    end

    private def update_fields(qi : QueuedItem, payload : QueuedItemUpdatePayload)
      if handler_id = payload.handler_id
        qi.handler = Auth::User.get!(id: handler_id)
      end
      if note = payload.note
        qi.note = note
      end
      if status = payload.status
        qi.change_status!(status.to_state)
      end

      qi.save!
    end

    private def schema
      @schema ||= QueuedItemUpdateSchema.new(@data)
    end

    # each items in the payload must belong to the same
    # organization as the current user
    private def authorize_items!(queue_items)
      queue_items.each do |qi|
        queue_org_id = qi.queue!.channel!.space!.owner!.organization_id
        raise Auth::AuthorizationError.new unless @organization_id == queue_org_id.to_s
      end
    end

    private def publish_queued_item_updated(qi : QueuedItem)
      ChannelEventPublisher.publish(qi.channel!,
        type: "queued_item_updated",
        key: "queued_item",
        value: QueuedItemSerializer.soft_serialize(qi))
    end
  end
end
