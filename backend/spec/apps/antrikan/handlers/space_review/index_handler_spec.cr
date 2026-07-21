require "./spec_helper"

describe Antrikan::SpaceReviewIndexHandler do
  it "returns all active reviews for the space" do
    space = create_space
    review1 = create_space_review(space: space, reviewer: create_user)
    review2 = create_space_review(space: space, reviewer: create_user)

    response = Marten::Spec.client.get(
      Marten.routes.reverse("antrikan:space:space_review:index", space_hashed_id: space.hashed_id)
    )

    response.status.should eq 200

    body = JSON.parse(response.content)
    body["reviews"].as_a.size.should eq 2
    ids = body["reviews"].as_a.map(&.["id"].as_s)
    ids.should contain review1.hashed_id
    ids.should contain review2.hashed_id
  end

  it "does not return reviews from other spaces" do
    space = create_space
    other_space = create_space
    create_space_review(space: other_space, reviewer: create_user)

    response = Marten::Spec.client.get(
      Marten.routes.reverse("antrikan:space:space_review:index", space_hashed_id: space.hashed_id)
    )

    response.status.should eq 200
    JSON.parse(response.content)["reviews"].as_a.should be_empty
  end

  it "does not return deleted reviews by default" do
    space = create_space
    review = create_space_review(space: space, reviewer: create_user)
    review.soft_delete!

    response = Marten::Spec.client.get(
      Marten.routes.reverse("antrikan:space:space_review:index", space_hashed_id: space.hashed_id)
    )

    response.status.should eq 200
    JSON.parse(response.content)["reviews"].as_a.should be_empty
  end

  it "includes deleted reviews when ?with_deleted=true" do
    space = create_space
    review = create_space_review(space: space, reviewer: create_user)
    review.soft_delete!

    response = Marten::Spec.client.get(
      "#{Marten.routes.reverse("antrikan:space:space_review:index", space_hashed_id: space.hashed_id)}?with_deleted=true"
    )

    response.status.should eq 200
    JSON.parse(response.content)["reviews"].as_a.size.should eq 1
  end

  it "returns an empty list when there are no reviews" do
    space = create_space

    response = Marten::Spec.client.get(
      Marten.routes.reverse("antrikan:space:space_review:index", space_hashed_id: space.hashed_id)
    )

    response.status.should eq 200
    JSON.parse(response.content)["reviews"].as_a.should be_empty
  end
end
