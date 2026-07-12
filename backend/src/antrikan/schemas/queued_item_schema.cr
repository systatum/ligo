module Antrikan
  BaseSchema.with_fields(
    fields: {
      item_slug:  {type: :string, strip: true},
      handler_id: {type: :string, strip: true},
      status:     {type: :enum, values: QueueStatus},
      note:       {type: :string, max_size: 255, strip: true},
      quantity:   {type: :int},
    },
    variants: {
      QueuedItemSchema:       {required: [:item_slug]},
      QueuedItemUpdateSchema: {disallowed: [:item_slug, :quantity]},
    }
  )

  class QueuedItemUpdateSchema
    validate :validate_has_fields

    private def validate_has_fields
      if !handler_id? && !status? && !note?
        errors.add(:base, "At least one field must be provided for update")
      end
    end
  end
end
