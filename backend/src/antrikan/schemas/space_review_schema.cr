module Antrikan
  BaseSchema.with_fields(
    fields: {
      rating: {type: :float, min_value: 0.0, max_value: 10.0},
      review: {type: :string},
    },
    variants: {
      SpaceReviewSchema:       {required: [:rating]},
      SpaceReviewUpdateSchema: {required: [] of Symbol},
    }
  )
end
