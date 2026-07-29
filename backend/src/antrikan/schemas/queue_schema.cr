module Antrikan
  BaseSchema.with_fields(
    fields: {
      queuer_id:      {type: :string, strip: true},
      handler_id:     {type: :string, strip: true},
      note:           {type: :string, max_size: 255, strip: true},
      status:         {type: :enum, values: QueueStatus},
      payment_status: {type: :enum, values: PaymentStatus},
      fully_paid_at:  {type: :date_time},
      voucher_code:   {type: :string, strip: true},
    },
    variants: {
      QueueSchema:       {required: [:queuer_id]},
      QueueUpdateSchema: {disallowed: [:queuer_id]},
    }
  )
end
