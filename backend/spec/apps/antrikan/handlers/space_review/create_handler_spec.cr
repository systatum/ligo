require "./spec_helper"

describe Antrikan::SpaceReviewCreateHandler do
  context "when the request is valid" do
    it "creates a review for the space" do
      user = create_user
      space = create_space

      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:space:space_review:create", space_hashed_id: space.hashed_id),
        data: {rating: 9.5, review: "Loved it"}.to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 201

      review = Antrikan::SpaceReview.last!
      review.space_id.should eq space.id
      review.reviewer_id.should eq user.id
      review.rating.should eq 9.5
      review.review.should eq "Loved it"

      response.content.should eq Antrikan::SpaceReviewSerializer.serialize(review)
    end

    it "allows a review without review text" do
      user = create_user
      space = create_space

      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:space:space_review:create", space_hashed_id: space.hashed_id),
        data: {rating: 7.0}.to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 201

      review = Antrikan::SpaceReview.last!
      review.review.should be_nil
    end
  end

  context "when the rating is out of range" do
    it "returns 422" do
      user = create_user
      space = create_space

      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:space:space_review:create", space_hashed_id: space.hashed_id),
        data: {rating: 10.5}.to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 422
    end
  end

  context "when the user already reviewed this space" do
    it "returns 422 and does not create a second review" do
      user = create_user
      space = create_space
      create_space_review(space: space, reviewer: user)

      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:space:space_review:create", space_hashed_id: space.hashed_id),
        data: {rating: 5.0}.to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 422
      Antrikan::SpaceReview.filter(space_id: space.id, reviewer_id: user.id).count.should eq 1
    end
  end

  context "when the user is not authenticated" do
    it "returns 400" do
      space = create_space

      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:space:space_review:create", space_hashed_id: space.hashed_id),
        data: {rating: 5.0}.to_json,
        content_type: "application/json"
      )

      response.status.should eq 400
    end

    context "when the space allows anonymous reviewers" do
      it "creates a review with no reviewer" do
        space = create_space(allow_anonymous_reviewer: true)

        response = Marten::Spec.client.post(
          Marten.routes.reverse("antrikan:space:space_review:create", space_hashed_id: space.hashed_id),
          data: {rating: 5.0}.to_json,
          content_type: "application/json"
        )

        response.status.should eq 201

        review = Antrikan::SpaceReview.last!
        review.reviewer_id.should be_nil

        response.content.should eq Antrikan::SpaceReviewSerializer.serialize(review)
      end
    end
  end
end
