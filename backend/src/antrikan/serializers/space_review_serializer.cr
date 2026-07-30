module Antrikan
  class SpaceReviewSerializer < ModelSerializer
    protected def fields
      record = @record.as(SpaceReview)

      {
        id:          record.hashed_id,
        space_id:    record.space!.hashed_id,
        reviewer_id: record.reviewer.try(&.hashed_id),
        channel_id:  record.channel.try(&.hashed_id),
        item_id:     record.item.try(&.slug),
        rating:      record.rating,
        review:      record.review,
        images:      fetch_uploaded_files(record.image_ids.try(&.ids)),
      }
    end
  end
end
