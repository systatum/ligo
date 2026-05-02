require "./spec_helper"

describe Antrikan::ItemCreateHandler do
  context "when the user is an admin" do
    it "it can create an item without optional fields" do
      user = create_user
      channel = create_channel

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
      channel = create_channel

      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:channel:item:create", channel_hashed_id: channel.hashed_id),
        data: {
          name:         "9AM",
          order:        2,
          daily_cap:    5,
          is_monitored: true,
          description:  "Morning slot",
        }.to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 201

      item = Antrikan::Item.last!
      item.name.should eq "9AM"
      item.order.should eq 2
      item.daily_cap.should eq 5
      item.is_monitored.should eq true
      item.description.should eq "Morning slot"
    end

    it "creates an item with a negative daily_cap (no cap)" do
      user = create_user
      channel = create_channel

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
      channel = create_channel

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
  end

  context "when name is missing" do
    it "returns 422" do
      user = create_user
      channel = create_channel

      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:channel:item:create", channel_hashed_id: channel.hashed_id),
        data: ({} of String => String).to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 422
    end

    it "when main_image is not an image" do
      user = create_user
      channel = create_channel

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

  context "when the user is not an admin" do
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
