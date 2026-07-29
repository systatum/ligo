module Antrikan
  BaseSchema.with_fields(
    fields: {
      item_slug:   {type: :string, strip: true},
      handler_id:  {type: :string, strip: true},
      status:      {type: :enum, values: QueueStatus},
      note:        {type: :string, max_size: 255, strip: true},
      cancel_note: {type: :string, max_size: 255, strip: true},
      quantity:    {type: :int},
    },
    variants: {
      QueuedItemSchema: {required: [:item_slug], disallowed: [:cancel_note]},
      # update variant is separate to support bulk update
    }
  )

  class QueuedItemUpdateSchema < BaseSchema
    field :items, :json, required: true
  end
end
