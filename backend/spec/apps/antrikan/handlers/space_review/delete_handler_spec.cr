require "./spec_helper"

describe Antrikan::SpaceReviewDeleteHandler do
  context "when the user is the review's author" do
    it "soft-deletes the review" do
      author = create_user
      review = create_space_review(reviewer: author)
      review_id = review.id!

      response = Marten::Spec.client.delete(
        Marten.routes.reverse("antrikan:space_review:delete", space_review_hashed_id: review.hashed_id),
        headers: {authorization: "Bearer #{author.jwt_token}"}
      )

      response.status.should eq 200

      deleted = Antrikan::SpaceReview.unscoped.get!(id: review_id)
      deleted.deleted_at.should be_a Time
    end
  end

  context "when the user is the space's owner (moderation) but not the author" do
    it "soft-deletes the review" do
      owner = create_user
      space = create_space(manager: owner)
      author = create_user
      review = create_space_review(space: space, reviewer: author)
      review_id = review.id!

      response = Marten::Spec.client.delete(
        Marten.routes.reverse("antrikan:space_review:delete", space_review_hashed_id: review.hashed_id),
        headers: {authorization: "Bearer #{owner.jwt_token}"}
      )

      response.status.should eq 200

      deleted = Antrikan::SpaceReview.unscoped.get!(id: review_id)
      deleted.deleted_at.should be_a Time
    end
  end

  context "when the user is neither the author nor the space owner" do
    it "returns 403 and does not delete the review" do
      space = create_space
      author = create_user
      unrelated_user = create_user
      review = create_space_review(space: space, reviewer: author)

      response = Marten::Spec.client.delete(
        Marten.routes.reverse("antrikan:space_review:delete", space_review_hashed_id: review.hashed_id),
        headers: {authorization: "Bearer #{unrelated_user.jwt_token}"}
      )

      response.status.should eq 403

      review.reload
      review.deleted_at.should be_nil
    end
  end

  context "when the user is not authenticated" do
    it "returns 400 and does not delete the review" do
      review = create_space_review

      response = Marten::Spec.client.delete(
        Marten.routes.reverse("antrikan:space_review:delete", space_review_hashed_id: review.hashed_id)
      )

      response.status.should eq 400

      review.reload
      review.deleted_at.should be_nil
    end
  end
end
