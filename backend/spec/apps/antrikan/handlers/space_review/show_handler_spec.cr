require "./spec_helper"

describe Antrikan::SpaceReviewShowHandler do
  context "with valid request" do
    it "returns the review" do
      review = create_space_review(rating: 6.5, review: "Decent")

      response = Marten::Spec.client.get(
        Marten.routes.reverse("antrikan:space_review:show", space_review_hashed_id: review.hashed_id)
      )

      response.status.should eq 200
      response.content.should eq Antrikan::SpaceReviewSerializer.serialize(review)
    end
  end

  context "when the request has invalid or unexpected payload" do
    it "returns 404 if the review is deleted" do
      review = create_space_review
      review.soft_delete!

      response = Marten::Spec.client.get(
        Marten.routes.reverse("antrikan:space_review:show", space_review_hashed_id: review.hashed_id)
      )

      response.status.should eq 404
    end

    it "returns 404 if the review's space is deleted" do
      space = create_space
      review = create_space_review(space: space)
      space.soft_delete!

      response = Marten::Spec.client.get(
        Marten.routes.reverse("antrikan:space_review:show", space_review_hashed_id: review.hashed_id)
      )

      response.status.should eq 404
    end

    it "returns 404 if the hashed_id is non-existent" do
      response = Marten::Spec.client.get(
        Marten.routes.reverse("antrikan:space_review:show", space_review_hashed_id: IdConcealer.encode(999999999))
      )

      response.status.should eq 404
    end
  end
end
