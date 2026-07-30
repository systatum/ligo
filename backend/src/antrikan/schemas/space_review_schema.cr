module Antrikan
  BaseSchema.with_fields(
    fields: {
      rating:     {type: :float, min_value: 0.0, max_value: 10.0},
      review:     {type: :string},
      channel_id: {type: :string, strip: true},
      item_id:    {type: :string, strip: true},
      images:     {type: :array, of: :json, serializable: CarouselImagePayload},
    },
    variants: {
      SpaceReviewSchema:       {required: [:rating]},
      SpaceReviewUpdateSchema: {required: [] of Symbol},
    },
    validations: {
      validate_images_size: -> { validate_max_images(:images, images, 4) },
    }
  )
end
