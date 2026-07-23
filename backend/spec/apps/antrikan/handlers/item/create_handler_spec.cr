require "./spec_helper"

describe Antrikan::ItemCreateHandler do
  context "when the user owns the channel's space" do
    it "it can create an item without optional fields" do
      user = create_user
      space = create_space(manager: user)
      channel = create_channel(space: space)

      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:channel:item:create", channel_hashed_id: channel.hashed_id),
        data: {name: "8AM"}.to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 201

      item = Antrikan::Item.last!
      item.channel_id.should eq channel.id
      item.name.should eq "8AM"
      item.order.should eq 0
      item.daily_cap.should eq 0
      item.is_monitored.should eq false
      item.description.should be_nil
      item.main_image_file_id.should be_nil
      item.slug!.should_not be_nil

      response.content.should eq Antrikan::ItemSerializer.serialize(item)
    end

    it "creates an item with all optional fields" do
      user = create_user
      space = create_space(manager: user)
      channel = create_channel(space: space)

      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:channel:item:create", channel_hashed_id: channel.hashed_id),
        data: {
          name:          "9AM",
          order:         2,
          daily_cap:     5,
          unit_price:    15000,
          unit_currency: "USD",
          is_monitored:  true,
          description:   "Morning slot",
        }.to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 201

      item = Antrikan::Item.last!
      item.name.should eq "9AM"
      item.order.should eq 2
      item.daily_cap.should eq 5
      item.unit_price.should eq 15000
      item.unit_currency.should eq Antrikan::Currency::USD.value
      item.is_monitored.should eq true
      item.description.should eq "Morning slot"
    end

    it "creates an item with a negative daily_cap (no cap)" do
      user = create_user
      space = create_space(manager: user)
      channel = create_channel(space: space)

      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:channel:item:create", channel_hashed_id: channel.hashed_id),
        data: {name: "Consultation", daily_cap: -1}.to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 201

      item = Antrikan::Item.last!
      item.daily_cap.should eq -1
    end

    it "creates an item with a main image and returns it in the response" do
      user = create_user
      space = create_space(manager: user)
      channel = create_channel(space: space)

      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:channel:item:create", channel_hashed_id: channel.hashed_id),
        data: {
          name:       "10AM",
          main_image: {
            base64_bytes: Base64.encode(PNG_1X1),
            mimetype:     "image/png",
          },
        }.to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 201

      item = Antrikan::Item.last!
      item.main_image_file_id.should_not be_nil

      response.content.should eq Antrikan::ItemSerializer.serialize(item)
    end

    it "uploads and persists carousel images in submitted order" do
      user = create_user
      space = create_space(manager: user)
      channel = create_channel(space: space)

      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:channel:item:create", channel_hashed_id: channel.hashed_id),
        data: {
          name:            "Gallery Item",
          carousel_images: [
            {base64_bytes: Base64.encode(PNG_1X1), mimetype: "image/png"},
            {base64_bytes: Base64.encode(PNG_1X1), mimetype: "image/png"},
          ],
        }.to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 201

      item = Antrikan::Item.last!
      item.carousel_image_ids!.ids.size.should eq 2

      body = JSON.parse(response.content)
      images = body["carousel_images"].as_a
      images.size.should eq 2
      images[0]["url"].as_s.should_not be_empty
      images[0]["id"].as_s.should eq item.carousel_image_ids!.ids[0]
      images[1]["id"].as_s.should eq item.carousel_image_ids!.ids[1]
    end
  end

  context "when name is missing" do
    it "returns 422" do
      user = create_user
      space = create_space(manager: user)
      channel = create_channel(space: space)

      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:channel:item:create", channel_hashed_id: channel.hashed_id),
        data: ({} of String => String).to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 422
    end

    it "returns 422 when unit_currency is not a known currency" do
      user = create_user
      space = create_space(manager: user)
      channel = create_channel(space: space)

      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:channel:item:create", channel_hashed_id: channel.hashed_id),
        data: {name: "8AM", unit_currency: "GBP"}.to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 422
    end

    it "returns 422 when a carousel_images keep_id is given (nothing to keep on create)" do
      user = create_user
      space = create_space(manager: user)
      channel = create_channel(space: space)

      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:channel:item:create", channel_hashed_id: channel.hashed_id),
        data: {name: "8AM", carousel_images: [{keep_id: "some-uuid"}]}.to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 422
    end

    it "returns 422 when more than 6 carousel images are submitted" do
      user = create_user
      space = create_space(manager: user)
      channel = create_channel(space: space)
      images = (1..7).map { {base64_bytes: Base64.encode(PNG_1X1), mimetype: "image/png"} }

      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:channel:item:create", channel_hashed_id: channel.hashed_id),
        data: {name: "8AM", carousel_images: images}.to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 422
    end

    it "when main_image is not an image" do
      user = create_user
      space = create_space(manager: user)
      channel = create_channel(space: space)

      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:channel:item:create", channel_hashed_id: channel.hashed_id),
        data: {
          name:       "8AM",
          main_image: {
            base64_bytes: Base64.encode("not an image"),
            mimetype:     "text/plain",
          },
        }.to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 422
    end
  end

  context "when the user has an insufficient role and does not own the space" do
    it "returns 403" do
      user = create_user(role: Auth::Role::SECURITY_STAFF)
      channel = create_channel

      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:channel:item:create", channel_hashed_id: channel.hashed_id),
        data: {name: "8AM"}.to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 403
    end
  end

  context "when the user owns an unrelated space" do
    it "returns 403 and does not create the item" do
      user = create_user
      create_space(manager: user)
      channel = create_channel

      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:channel:item:create", channel_hashed_id: channel.hashed_id),
        data: {name: "8AM"}.to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 403
    end
  end

  context "when the user has OWNER role in the same organization as the space owner" do
    it "creates the item" do
      organization = create_organization
      space_owner = create_user(organization: organization)
      space = create_space(manager: space_owner)
      channel = create_channel(space: space)
      colleague = create_user(organization: organization, role: Auth::Role::OWNER)

      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:channel:item:create", channel_hashed_id: channel.hashed_id),
        data: {name: "8AM"}.to_json,
        headers: {authorization: "Bearer #{colleague.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 201
    end
  end

  context "when the user is not authenticated" do
    it "returns 400" do
      channel = create_channel

      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:channel:item:create", channel_hashed_id: channel.hashed_id),
        data: {name: "8AM"}.to_json,
        content_type: "application/json"
      )

      response.status.should eq 400
    end
  end
end
