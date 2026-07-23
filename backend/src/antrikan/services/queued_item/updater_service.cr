module Antrikan
  class QueuedItem::UpdaterService < BaseService(QueuedItem)
    def initialize(@queued_item : QueuedItem, @data : Marten::HTTP::Params::Data)
    end

    def run : ServiceResult(QueuedItem)
      return failure(schema.errors) unless schema.valid?
      return failure(:queue, "Cannot modify items on a paid queue") unless unpaid?
      return failure(:status, "Cannot delete this item at its current state") if past_predeletable_state?

      begin
        update_fields
        publish_queued_item_updated(@queued_item)
        success(@queued_item)
      rescue ex : AASM::AASMException
        failure(:status, ex.message || "Invalid status transition")
      rescue ex : Marten::DB::Errors::InvalidRecord
        failure(ex.record.errors)
      end
    end

    private def update_fields
      handler = schema.handler_id? ? Auth::User.get_by_hashed_id!(schema.handler_id!) : nil

      @queued_item.handler = handler if schema.handler_id?
      @queued_item.note = schema.note if schema.note?
      @queued_item.cancel_note = schema.cancel_note if schema.cancel_note? && becoming_canceled?
      @queued_item.change_status!(schema.status!.to_state) if schema.status?

      @queued_item.save!
    end

    private def becoming_canceled? : Bool
      schema.status? && schema.status! == QueueStatus::CANCELED
    end

    # True when this request is trying to cancel (delete) the item, but the item's
    # current state is already past the channel's configured predeletable_state cutoff.
    private def past_predeletable_state? : Bool
      becoming_canceled? && @queued_item.status! > @queued_item.channel!.predeletable_state!
    end

    private def unpaid? : Bool
      @queued_item.queue!.payment_status! == PaymentStatus::UNPAID.value
    end

    private def schema
      @schema ||= QueuedItemUpdateSchema.new(@data)
    end

    private def publish_queued_item_updated(qi : QueuedItem)
      ChannelEventPublisher.publish(qi.channel!,
        type: "queued_item_updated",
        key: "queued_item",
        value: QueuedItemSerializer.soft_serialize(qi))
    end
  end
end
