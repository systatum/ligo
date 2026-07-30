module Antrikan
  BaseSchema.with_fields(
    fields: {
      name:                    {type: :string, max_size: 255, strip: true},
      description:             {type: :string},
      logo:                    {type: :json, serializable: FilePayload},
      predeletable_state:      {type: :enum, values: QueueStatus},
      enforce_operating_hours: {type: :bool},
      max_item_piece:          {type: :int},
      parent_channel_id:       {type: :string, strip: true},
    },
    variants: {
      ChannelSchema:       {required: [:name]},
      ChannelUpdateSchema: nil,
    }
  )
end
