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

    it "attaches a channel from the same space" do
      author = create_user
      space = create_space
      channel = create_channel(space: space)
      review = create_space_review(space: space, reviewer: author, rating: 5.0)

      response = Marten::Spec.client.patch(
        Marten.routes.reverse("antrikan:space_review:update", space_review_hashed_id: review.hashed_id),
        data: {channel_id: channel.hashed_id}.to_json,
        headers: {authorization: "Bearer #{author.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 200

      review.reload
      review.channel_id.should eq channel.id
    end

    it "attaches uploaded images" do
      author = create_user
      review = create_space_review(reviewer: author, rating: 5.0)

      response = Marten::Spec.client.patch(
        Marten.routes.reverse("antrikan:space_review:update", space_review_hashed_id: review.hashed_id),
        data: {
          images: [
            {base64_bytes: Base64.encode(PNG_1X1), mimetype: "image/png"},
          ],
        }.to_json,
        headers: {authorization: "Bearer #{author.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 200

      review.reload
      review.image_ids.not_nil!.ids.size.should eq 1
    end

    it "keeps an existing image via keep_id and adds a new one" do
      author = create_user
      existing_file = create_uploaded_file_metadata
      review = create_space_review(reviewer: author, rating: 5.0)
      review.image_ids = UploadedFileIds.new(ids: [existing_file.id.to_s])
      review.save!

      response = Marten::Spec.client.patch(
        Marten.routes.reverse("antrikan:space_review:update", space_review_hashed_id: review.hashed_id),
        data: {
          images: [
            {keep_id: existing_file.id.to_s},
            {base64_bytes: Base64.encode(PNG_1X1), mimetype: "image/png"},
          ],
        }.to_json,
        headers: {authorization: "Bearer #{author.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 200

      review.reload
      review.image_ids.not_nil!.ids.size.should eq 2
      review.image_ids.not_nil!.ids.should contain existing_file.id.to_s
    end

    it "returns 422 for a keep_id that isn't currently on the review" do
      author = create_user
      other_file = create_uploaded_file_metadata
      review = create_space_review(reviewer: author, rating: 5.0)

      response = Marten::Spec.client.patch(
        Marten.routes.reverse("antrikan:space_review:update", space_review_hashed_id: review.hashed_id),
        data: {images: [{keep_id: other_file.id.to_s}]}.to_json,
        headers: {authorization: "Bearer #{author.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 422
    end

    it "does not change images when the images field is not provided" do
      author = create_user
      existing_file = create_uploaded_file_metadata
      review = create_space_review(reviewer: author, rating: 5.0)
      review.image_ids = UploadedFileIds.new(ids: [existing_file.id.to_s])
      review.save!

      response = Marten::Spec.client.patch(
        Marten.routes.reverse("antrikan:space_review:update", space_review_hashed_id: review.hashed_id),
        data: {rating: 8.0}.to_json,
        headers: {authorization: "Bearer #{author.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 200

      review.reload
      review.image_ids.not_nil!.ids.should eq [existing_file.id.to_s]
    end

    it "returns 422 when channel_id and item_id are both given" do
      author = create_user
      space = create_space
      channel = create_channel(space: space)
      item = create_item(channel: channel)
      review = create_space_review(space: space, reviewer: author, rating: 5.0)

      response = Marten::Spec.client.patch(
        Marten.routes.reverse("antrikan:space_review:update", space_review_hashed_id: review.hashed_id),
        data: {channel_id: channel.hashed_id, item_id: item.slug}.to_json,
        headers: {authorization: "Bearer #{author.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 422
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
