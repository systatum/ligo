module Antrikan
  class QueueSerializer < ModelSerializer
    protected def fields
      record = @record.as(Queue)

      {
        id:             record.slug,
        channel_id:     record.channel!.hashed_id,
        queuer_id:      record.queuer!.hashed_id,
        handler_id:     record.handler.try(&.hashed_id),
        note:           record.note,
        status:         record.status,
        payment_status: record.payment_status,
        total_price:    record.total_price,
        fully_paid_at:  record.fully_paid_at,
        attended_at:    record.attended_at,
        packed_at:      record.packed_at,
        ready_at:       record.ready_at,
        dispatched_at:  record.dispatched_at,
        delivered_at:   record.delivered_at,
      }
    end
  end
end
