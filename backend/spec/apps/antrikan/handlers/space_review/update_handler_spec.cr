require "./spec_helper"

describe Antrikan::SpaceReviewUpdateHandler do
  context "when the user is the review's author" do
    it "updates the rating and review text" do
      author = create_user
      review = create_space_review(reviewer: author, rating: 5.0, review: "Original")

      response = Marten::Spec.client.patch(
        Marten.routes.reverse("antrikan:space_review:update", space_review_hashed_id: review.hashed_id),
        data: {rating: 9.0, review: "Updated"}.to_json,
        headers: {authorization: "Bearer #{author.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 200

      review.reload
      review.rating.should eq 9.0
      review.review.should eq "Updated"
    end

    it "returns 422 for an out-of-range rating" do
      author = create_user
      review = create_space_review(reviewer: author, rating: 5.0)

      response = Marten::Spec.client.patch(
        Marten.routes.reverse("antrikan:space_review:update", space_review_hashed_id: review.hashed_id),
        data: {rating: -1.0}.to_json,
        headers: {authorization: "Bearer #{author.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 422

      review.reload
      review.rating.should eq 5.0
    end
  end

  context "when the user is not the review's author" do
    it "returns 403 and does not update the review, even for the space owner" do
      owner = create_user
      space = create_space(manager: owner)
      author = create_user
      review = create_space_review(space: space, reviewer: author, rating: 5.0, review: "Original")

      response = Marten::Spec.client.patch(
        Marten.routes.reverse("antrikan:space_review:update", space_review_hashed_id: review.hashed_id),
        data: {rating: 1.0, review: "Hacked"}.to_json,
        headers: {authorization: "Bearer #{owner.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 403

      review.reload
      review.rating.should eq 5.0
      review.review.should eq "Original"
    end
  end

  context "when the user is not authenticated" do
    it "returns 400 and does not update the review" do
      review = create_space_review(rating: 5.0)

      response = Marten::Spec.client.patch(
        Marten.routes.reverse("antrikan:space_review:update", space_review_hashed_id: review.hashed_id),
        data: {rating: 1.0}.to_json,
        content_type: "application/json"
      )

      response.status.should eq 400

      review.reload
      review.rating.should eq 5.0
    end
  end
end
