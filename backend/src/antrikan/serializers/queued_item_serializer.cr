module Antrikan
  class QueuedItemSerializer < ModelSerializer
    protected def fields
      record = @record.as(QueuedItem)

      {
        id:         record.id.to_s,
        queue_id:   record.queue!.slug,
        channel_id: record.channel!.hashed_id,
        item_id:    record.item!.slug,
        handler_id: record.handler.try(&.hashed_id),
        status:     record.status,
        note:       record.note,
        unit_price: record.unit_price,
        quantity:   record.quantity,
      }
    end
  end
end
