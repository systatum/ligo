module Antrikan
  class QueuedItem::UpdaterService < BaseService(Array(QueuedItem))
    def initialize(@organization_id : String, @data : Marten::HTTP::Params::Data)
    end

    def run : ServiceResult(Array(QueuedItem))
      return failure(schema.errors) unless schema.valid?

      items_array = schema.items!.as_a?
      return failure(:items, "must be an array") unless items_array

      items_payload = Array(QueuedItemUpdatePayload).from_json(items_array.to_json)
      return failure(:items, "must be a non-empty array") if items_payload.empty?

      if items_payload.any? { |payload| payload.handler_id.nil? && payload.status.nil? && payload.note.nil? }
        return failure(:items, "At least one field must be provided for update")
      end

      queue_items = QueuedItem.unscoped.filter(id__in: items_payload.map(&.id)).to_a
      unless queue_items.size == items_payload.size
        return failure(:items, "Some items not found")
      end

      authorize_items!(queue_items)

      id_to_queue_item = queue_items.index_by { |qi| qi.id.to_s }
      updated = [] of QueuedItem

      QueuedItem.transaction do
        items_payload.each do |payload|
          qi = id_to_queue_item[payload.id]
          qi.skip_parent_sync = true
          update_fields(qi, payload)
          updated << qi
        end

        queue_items.map(&.queue!).uniq(&.id!).each(&.sync_from_queued_items!)
      end

      updated.each { |qi| publish_queued_item_updated(qi) }

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
        qi.handler = Auth::User.get_by_hashed_id!(handler_id)
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
      authorized_count = QueuedItem.unscoped
        .filter(id__in: queue_items.map(&.id))
        .filter(queue__channel__space__owner__organization_id: @organization_id.to_i64)
        .count

      raise Auth::AuthorizationError.new unless authorized_count == queue_items.size
    end

    private def publish_queued_item_updated(qi : QueuedItem)
      ChannelEventPublisher.publish(qi.channel!,
        type: "queued_item_updated",
        key: "queued_item",
        value: QueuedItemSerializer.soft_serialize(qi))
    end
  end
end
