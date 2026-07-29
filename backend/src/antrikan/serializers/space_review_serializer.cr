module Antrikan
  class SpaceReviewSerializer < ModelSerializer
    protected def fields
      record = @record.as(SpaceReview)

      {
        id:          record.hashed_id,
        space_id:    record.space!.hashed_id,
        reviewer_id: record.reviewer!.hashed_id,
        rating:      record.rating,
        review:      record.review,
      }
    end
  end
end
