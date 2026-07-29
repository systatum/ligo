module Antrikan
  class QueuedItemSerializer < ModelSerializer
    protected def fields
      record = @record.as(QueuedItem)

      {
        id:                  record.id.to_s,
        queue_id:            record.queue!.slug,
        channel_id:          record.channel!.hashed_id,
        item_id:             record.item!.slug,
        handler_id:          record.handler.try(&.hashed_id),
        status:              record.status,
        note:                record.note,
        cancel_note:         record.cancel_note,
        unit_price:          record.unit_price,
        quantity:            record.quantity,
        rank:                record.rank,
        applied_voucher_ids: record.applied_voucher_ids.try(&.ids) || [] of Int64,
        discount_amount:     BigFloat.new(record.unit_price! * record.quantity!) - record.discounted_line_total,
        discounted_total:    record.discounted_line_total,
      }
    end
  end
end
