require "./spec_helper"

describe Antrikan::SpaceUpdateHandler do
  context "when the user is authorized" do
    it "updates the space" do
      user = create_user
      space = create_space(manager: user, name: "Original Name")

      response = Marten::Spec.client.patch(
        Marten.routes.reverse("antrikan:space:update", space_hashed_id: space.hashed_id),
        data: {name: "Updated Name"}.to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 200

      space.reload
      space.name.should eq "Updated Name"

      response.content.should eq Antrikan::SpaceSerializer.serialize(space)
    end

    it "updates optional fields" do
      user = create_user
      space = create_space(manager: user, need_manual_approval: false, has_operating_hours: false)

      response = Marten::Spec.client.patch(
        Marten.routes.reverse("antrikan:space:update", space_hashed_id: space.hashed_id),
        data: {
          name:                 space.name,
          need_manual_approval: true,
          has_operating_hours:  true,
        }.to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 200

      space.reload
      space.need_manual_approval.should be_true
      space.has_operating_hours.should be_true
    end

    it "does not change the code" do
      user = create_user
      space = create_space(manager: user)
      original_code = space.code!

      response = Marten::Spec.client.patch(
        Marten.routes.reverse("antrikan:space:update", space_hashed_id: space.hashed_id),
        data: {name: "New Name"}.to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 200

      space.reload
      space.code!.should eq original_code
    end

    it "uploads a logo when provided and serializes a resolved URL" do
      user = create_user
      space = create_space(manager: user)

      response = Marten::Spec.client.patch(
        Marten.routes.reverse("antrikan:space:update", space_hashed_id: space.hashed_id),
        data: {
          name: space.name,
          logo: {
            base64_bytes: Base64.encode(PNG_1X1),
            mimetype:     "image/png",
          },
        }.to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 200

      space.reload
      space.logo_file_id.should_not be_nil

      body = JSON.parse(response.content)
      body["logo"].as_s.should_not be_empty
    end

    it "serializes logo as null when the space has none" do
      user = create_user
      space = create_space(manager: user)

      response = Marten::Spec.client.patch(
        Marten.routes.reverse("antrikan:space:update", space_hashed_id: space.hashed_id),
        data: {name: space.name}.to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 200

      body = JSON.parse(response.content)
      body["logo"].raw.should be_nil
    end

    it "reorders carousel images using keep_id only, without re-uploading" do
      user = create_user
      space = create_space(manager: user)
      first = create_uploaded_file_metadata
      second = create_uploaded_file_metadata
      space.carousel_image_ids = UploadedFileIds.new(ids: [first.id.to_s, second.id.to_s])
      space.save!

      response = Marten::Spec.client.patch(
        Marten.routes.reverse("antrikan:space:update", space_hashed_id: space.hashed_id),
        data: {
          name:            space.name,
          carousel_images: [{keep_id: second.id.to_s}, {keep_id: first.id.to_s}],
        }.to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 200

      space.reload
      space.carousel_image_ids!.ids.should eq [second.id.to_s, first.id.to_s]
    end

    it "mixes a kept image with a freshly uploaded one" do
      user = create_user
      space = create_space(manager: user)
      existing = create_uploaded_file_metadata
      space.carousel_image_ids = UploadedFileIds.new(ids: [existing.id.to_s])
      space.save!

      response = Marten::Spec.client.patch(
        Marten.routes.reverse("antrikan:space:update", space_hashed_id: space.hashed_id),
        data: {
          name:            space.name,
          carousel_images: [
            {keep_id: existing.id.to_s},
            {base64_bytes: Base64.encode(PNG_1X1), mimetype: "image/png"},
          ],
        }.to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 200

      space.reload
      space.carousel_image_ids!.ids.size.should eq 2
      space.carousel_image_ids!.ids[0].should eq existing.id.to_s
      space.carousel_image_ids!.ids[1].should_not eq existing.id.to_s
    end

    it "returns 422 when keep_id does not reference an existing image on this space" do
      user = create_user
      space = create_space(manager: user)
      unrelated = create_uploaded_file_metadata

      response = Marten::Spec.client.patch(
        Marten.routes.reverse("antrikan:space:update", space_hashed_id: space.hashed_id),
        data: {
          name:            space.name,
          carousel_images: [{keep_id: unrelated.id.to_s}],
        }.to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 422

      space.reload
      space.carousel_image_ids.should be_nil
    end

    it "updates address, phone, and email" do
      user = create_user
      space = create_space(manager: user)

      response = Marten::Spec.client.patch(
        Marten.routes.reverse("antrikan:space:update", space_hashed_id: space.hashed_id),
        data: {
          name:    space.name,
          address: "456 Side St",
          phone:   "555-6789",
          email:   "updated@example.com",
        }.to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 200

      space.reload
      space.address.should eq "456 Side St"
      space.phone.should eq "555-6789"
      space.email.should eq "updated@example.com"
    end

    it "does not change the business's name when the space's name changes" do
      user = create_user
      space = create_space(manager: user, name: "Original Name")
      business_name_before = space.owner!.name

      response = Marten::Spec.client.patch(
        Marten.routes.reverse("antrikan:space:update", space_hashed_id: space.hashed_id),
        data: {name: "Renamed Space"}.to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 200

      space.reload
      space.name.should eq "Renamed Space"
      space.owner!.name.should eq business_name_before
    end

    it "a business owner who is not the space's manager can still update the space" do
      manager = create_user
      business = create_business(owner: create_user)
      owner = business.owner!
      space = create_space(manager: manager, business: business)

      response = Marten::Spec.client.patch(
        Marten.routes.reverse("antrikan:space:update", space_hashed_id: space.hashed_id),
        data: {name: "Updated by business owner"}.to_json,
        headers: {authorization: "Bearer #{owner.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 200

      space.reload
      space.name.should eq "Updated by business owner"
    end

    it "returns 403 when space belongs to another user" do
      user1 = create_user
      user2 = create_user
      space = create_space(manager: user2)

      response = Marten::Spec.client.patch(
        Marten.routes.reverse("antrikan:space:update", space_hashed_id: space.hashed_id),
        data: {name: "Hacked Name"}.to_json,
        headers: {authorization: "Bearer #{user1.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 403
    end
  end

  context "when the user is not authorized" do
    it "returns 400" do
      user = create_user
      space = create_space(manager: user)

      response = Marten::Spec.client.patch(
        Marten.routes.reverse("antrikan:space:update", space_hashed_id: space.hashed_id),
        data: {name: "New Name"}.to_json,
        content_type: "application/json"
      )

      response.status.should eq 400
      space.reload
      space.name.should_not eq "New Name"
    end
  end
end
