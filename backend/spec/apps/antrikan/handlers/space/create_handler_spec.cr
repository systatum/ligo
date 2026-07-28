require "./spec_helper"

describe Antrikan::SpaceCreateHandler do
  context "when the user is authorized" do
    context "with a valid schema" do
      it "creates a new space with auto-generated code" do
        user = create_user

        response = Marten::Spec.client.post(
          Marten.routes.reverse("antrikan:space:create"),
          data: {name: "My Queue Space"}.to_json,
          headers: {authorization: "Bearer #{user.jwt_token}"},
          content_type: "application/json"
        )

        response.status.should eq 201

        space = Antrikan::Space.last!
        space.manager_id.should eq user.id
        space.name.should eq "My Queue Space"
        space.code!.size.should eq 5

        response.content.should eq Antrikan::SpaceSerializer.serialize(space)
      end

      it "creates a space with optional fields" do
        user = create_user

        response = Marten::Spec.client.post(
          Marten.routes.reverse("antrikan:space:create"),
          data: {
            name:                 "Premium Queue",
            need_manual_approval: true,
            has_operating_hours:  true,
          }.to_json,
          headers: {authorization: "Bearer #{user.jwt_token}"},
          content_type: "application/json"
        )

        response.status.should eq 201

        space = Antrikan::Space.last!
        space.name.should eq "Premium Queue"
        space.need_manual_approval.should be_true
        space.has_operating_hours.should be_true

        response.content.should eq Antrikan::SpaceSerializer.serialize(space)
      end

      it "creates a space with address, phone, and email" do
        user = create_user

        response = Marten::Spec.client.post(
          Marten.routes.reverse("antrikan:space:create"),
          data: {
            name:    "Contactable Space",
            address: "123 Main St",
            phone:   "555-1234",
            email:   "space@example.com",
          }.to_json,
          headers: {authorization: "Bearer #{user.jwt_token}"},
          content_type: "application/json"
        )

        response.status.should eq 201

        space = Antrikan::Space.last!
        space.address.should eq "123 Main St"
        space.phone.should eq "555-1234"
        space.email.should eq "space@example.com"
      end

      it "creates a space with a description" do
        user = create_user

        response = Marten::Spec.client.post(
          Marten.routes.reverse("antrikan:space:create"),
          data: {
            name:        "Described Space",
            description: "A cozy queue space downtown",
          }.to_json,
          headers: {authorization: "Bearer #{user.jwt_token}"},
          content_type: "application/json"
        )

        response.status.should eq 201

        space = Antrikan::Space.last!
        space.description.should eq "A cozy queue space downtown"

        response.content.should eq Antrikan::SpaceSerializer.serialize(space)
      end

      it "creates a space with geo and postal fields" do
        user = create_user

        response = Marten::Spec.client.post(
          Marten.routes.reverse("antrikan:space:create"),
          data: {
            name:                "Geolocated Space",
            address_city_code:   100010001,
            address_postal_code: "23615",
            latitude:            5.5577,
            longitude:           95.3222,
          }.to_json,
          headers: {authorization: "Bearer #{user.jwt_token}"},
          content_type: "application/json"
        )

        response.status.should eq 201

        space = Antrikan::Space.last!
        space.address_city_code.should eq 100010001
        space.address_postal_code.should eq "23615"
        space.latitude.should eq 5.5577
        space.longitude.should eq 95.3222

        response.content.should eq Antrikan::SpaceSerializer.serialize(space)
      end

      it "auto-creates a business owned by the creating user, named after the space" do
        user = create_user

        response = Marten::Spec.client.post(
          Marten.routes.reverse("antrikan:space:create"),
          data: {name: "Auto Business Space"}.to_json,
          headers: {authorization: "Bearer #{user.jwt_token}"},
          content_type: "application/json"
        )

        response.status.should eq 201

        space = Antrikan::Space.last!
        business = space.owner!
        business.owner_id.should eq user.id
        business.name.should eq "Auto Business Space"

        body = JSON.parse(response.content)
        body["business_id"].as_s.should eq business.hashed_id
      end

      it "uses business_name for the auto-created business when provided" do
        user = create_user

        response = Marten::Spec.client.post(
          Marten.routes.reverse("antrikan:space:create"),
          data: {name: "Downtown Branch", business_name: "Acme Coffee Co"}.to_json,
          headers: {authorization: "Bearer #{user.jwt_token}"},
          content_type: "application/json"
        )

        response.status.should eq 201

        space = Antrikan::Space.last!
        space.owner!.name.should eq "Acme Coffee Co"
      end

      it "uploads and persists carousel images in submitted order" do
        user = create_user

        response = Marten::Spec.client.post(
          Marten.routes.reverse("antrikan:space:create"),
          data: {
            name:            "Gallery Space",
            carousel_images: [
              {base64_bytes: Base64.encode(PNG_1X1), mimetype: "image/png"},
              {base64_bytes: Base64.encode(PNG_1X1), mimetype: "image/png"},
            ],
          }.to_json,
          headers: {authorization: "Bearer #{user.jwt_token}"},
          content_type: "application/json"
        )

        response.status.should eq 201

        space = Antrikan::Space.last!
        space.carousel_image_ids!.ids.size.should eq 2

        body = JSON.parse(response.content)
        images = body["carousel_images"].as_a
        images.size.should eq 2
        images[0]["url"].as_s.should_not be_empty
        images[0]["id"].as_s.should eq space.carousel_image_ids!.ids[0]
        images[1]["id"].as_s.should eq space.carousel_image_ids!.ids[1]
      end
    end

    context "with an invalid carousel_images payload" do
      it "returns 422 when a keep_id is given (nothing to keep on create)" do
        user = create_user

        response = Marten::Spec.client.post(
          Marten.routes.reverse("antrikan:space:create"),
          data: {
            name:            "Bad Gallery Space",
            carousel_images: [{keep_id: "some-uuid"}],
          }.to_json,
          headers: {authorization: "Bearer #{user.jwt_token}"},
          content_type: "application/json"
        )

        response.status.should eq 422
      end

      it "returns 422 when more than 6 images are submitted" do
        user = create_user
        images = (1..7).map { {base64_bytes: Base64.encode(PNG_1X1), mimetype: "image/png"} }

        response = Marten::Spec.client.post(
          Marten.routes.reverse("antrikan:space:create"),
          data: {name: "Too Many Images", carousel_images: images}.to_json,
          headers: {authorization: "Bearer #{user.jwt_token}"},
          content_type: "application/json"
        )

        response.status.should eq 422
      end
    end

    context "with an invalid schema" do
      it "raises an error" do
        user = create_user

        response = Marten::Spec.client.post(
          Marten.routes.reverse("antrikan:space:create"),
          data: ({} of String => String).to_json,
          headers: {authorization: "Bearer #{user.jwt_token}"},
          content_type: "application/json"
        )

        response.status.should eq 422
      end
    end
  end

  context "when the user is not authorized" do
    it "returns 400" do
      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:space:create"),
        data: {name: "Test Space"}.to_json,
        content_type: "application/json"
      )

      response.status.should eq 400
    end
  end
end
