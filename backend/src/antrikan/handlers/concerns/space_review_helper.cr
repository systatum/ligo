module Antrikan
  module SpaceReviewHelper
    @space_review : SpaceReview?
    @schema : SpaceReviewSchema?

    private def space_review
      @space_review ||= SpaceReview
        .filter_by_hashed_id(params["space_review_hashed_id"].to_s)
        .get!
    end

    private def authorized_to_edit_review?
      space_review.reviewer == current_user!
    end

    private def authorized_to_delete_review?
      space_review.reviewer == current_user! || space_review.space!.owned_by?(current_user!)
    end

    private def schema
      @schema ||= SpaceReviewSchema.new(request.data)
    end
  end
end
