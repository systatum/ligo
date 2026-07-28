module Antrikan
  class PaymentSerializer < ModelSerializer
    protected def fields
      record = @record.as(Payment)

      {
        id:                          record.hashed_id,
        queue_id:                    record.queue!.slug,
        amount:                      record.amount,
        method:                      record.method,
        note:                        record.note,
        recorded_by_id:              record.recorded_by!.hashed_id,
        amount_refunded:             record.amount_refunded.to_s,
        remaining_refundable_amount: record.remaining_refundable_amount.to_s,
      }
    end
  end
end
