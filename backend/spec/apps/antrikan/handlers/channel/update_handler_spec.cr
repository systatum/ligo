require "./spec_helper"

describe Antrikan::ChannelUpdateHandler do
  context "when the user is an admin" do
    it "updates the name" do
      user = create_user
      channel = create_channel(name: "Old Name")

      response = Marten::Spec.client.patch(
        Marten.routes.reverse("antrikan:channel:update", channel_hashed_id: channel.hashed_id),
        data: {name: "New Name"}.to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 200

      channel.reload
      channel.name.should eq "New Name"

      response.content.should eq Antrikan::ChannelSerializer.serialize(channel)
    end

    it "updates the description" do
      user = create_user
      channel = create_channel(description: nil)

      response = Marten::Spec.client.patch(
        Marten.routes.reverse("antrikan:channel:update", channel_hashed_id: channel.hashed_id),
        data: {description: "All beverages"}.to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 200

      channel.reload
      channel.description.should eq "All beverages"
    end

    it "clears the description when sent as null" do
      user = create_user
      channel = create_channel(description: "Some description")

      response = Marten::Spec.client.patch(
        Marten.routes.reverse("antrikan:channel:update", channel_hashed_id: channel.hashed_id),
        data: {description: nil}.to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 200

      channel.reload
      channel.description.should be_nil
    end

    it "uploads a logo when provided" do
      user = create_user
      channel = create_channel

      response = Marten::Spec.client.patch(
        Marten.routes.reverse("antrikan:channel:update", channel_hashed_id: channel.hashed_id),
        data: {
          logo: {
            base64_bytes: Base64.encode(PNG_1X1),
            mimetype:     "image/png",
          },
        }.to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 200

      channel.reload
      channel.logo_file_id.should_not be_nil
    end

    it "clears the logo when sent as null" do
      user = create_user
      file = create_uploaded_file_metadata
      channel = create_channel(logo_file_id: file.id)

      response = Marten::Spec.client.patch(
        Marten.routes.reverse("antrikan:channel:update", channel_hashed_id: channel.hashed_id),
        data: {logo: nil}.to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 200

      channel.reload
      channel.logo_file_id.should be_nil
    end

    it "does not change fields that are not in the request body" do
      user = create_user
      channel = create_channel(name: "Original", description: "Original desc")

      response = Marten::Spec.client.patch(
        Marten.routes.reverse("antrikan:channel:update", channel_hashed_id: channel.hashed_id),
        data: {name: "Updated"}.to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 200

      channel.reload
      channel.name.should eq "Updated"
      channel.description.should eq "Original desc"
    end

    it "returns 422 for a name that is too long" do
      user = create_user
      channel = create_channel

      response = Marten::Spec.client.patch(
        Marten.routes.reverse("antrikan:channel:update", channel_hashed_id: channel.hashed_id),
        data: {name: "a" * 256}.to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 422
    end

    it "returns 422 when logo is not an image" do
      user = create_user
      channel = create_channel

      response = Marten::Spec.client.patch(
        Marten.routes.reverse("antrikan:channel:update", channel_hashed_id: channel.hashed_id),
        data: {
          logo: {
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
      channel = create_channel(name: "Original")

      response = Marten::Spec.client.patch(
        Marten.routes.reverse("antrikan:channel:update", channel_hashed_id: channel.hashed_id),
        data: {name: "Hacked"}.to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 403

      channel.reload
      channel.name.should eq "Original"
    end
  end

  context "when the user is not authenticated" do
    it "returns 400" do
      channel = create_channel(name: "Original")

      response = Marten::Spec.client.patch(
        Marten.routes.reverse("antrikan:channel:update", channel_hashed_id: channel.hashed_id),
        data: {name: "Hacked"}.to_json,
        content_type: "application/json"
      )

      response.status.should eq 400

      channel.reload
      channel.name.should eq "Original"
    end
  end
end
