require "./spec_helper"

describe Antrikan::ChannelCreateHandler do
  context "when the user is an admin" do
    it "creates a channel with a name" do
      user = create_user
      space = create_space(manager: user)

      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:space:channel:create", space_hashed_id: space.hashed_id),
        data: {name: "Beverages"}.to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 201

      channel = Antrikan::Channel.last!
      channel.space_id.should eq space.id
      channel.name.should eq "Beverages"
      channel.description.should be_nil
      channel.logo_file_id.should be_nil
      channel.predeletable_state.should eq Antrikan::QueueStatus::ATTENDED.value
      channel.enforce_operating_hours.should be_false

      response.content.should eq Antrikan::ChannelSerializer.serialize(channel)
    end

    it "creates a channel with enforce_operating_hours enabled" do
      user = create_user
      space = create_space(manager: user)

      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:space:channel:create", space_hashed_id: space.hashed_id),
        data: {name: "Consultations", enforce_operating_hours: true}.to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 201

      channel = Antrikan::Channel.last!
      channel.enforce_operating_hours.should be_true
    end

    it "creates a channel with a description" do
      user = create_user
      space = create_space(manager: user)

      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:space:channel:create", space_hashed_id: space.hashed_id),
        data: {name: "Noodles", description: "All noodle dishes"}.to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 201

      channel = Antrikan::Channel.last!
      channel.description.should eq "All noodle dishes"
    end

    it "creates a channel with a logo and returns it in the response" do
      user = create_user
      space = create_space(manager: user)

      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:space:channel:create", space_hashed_id: space.hashed_id),
        data: {
          name: "Desserts",
          logo: {
            base64_bytes: Base64.encode(PNG_1X1),
            mimetype:     "image/png",
          },
        }.to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 201

      channel = Antrikan::Channel.last!
      channel.logo_file_id.should_not be_nil

      response.content.should eq Antrikan::ChannelSerializer.serialize(channel)
    end

    it "returns 422 when name is missing" do
      user = create_user
      space = create_space(manager: user)

      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:space:channel:create", space_hashed_id: space.hashed_id),
        data: ({} of String => String).to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 422
    end

    it "returns 422 when logo is not an image" do
      user = create_user
      space = create_space(manager: user)

      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:space:channel:create", space_hashed_id: space.hashed_id),
        data: {
          name: "Beverages",
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

    it "returns 422 when predeletable_state is not a known state" do
      user = create_user
      space = create_space(manager: user)

      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:space:channel:create", space_hashed_id: space.hashed_id),
        data: {name: "Beverages", predeletable_state: "NOT_A_STATE"}.to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 422
    end
  end

  context "when the user is not an admin" do
    it "returns 403" do
      user = create_user(role: Auth::Role::SECURITY_STAFF)
      space = create_space

      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:space:channel:create", space_hashed_id: space.hashed_id),
        data: {name: "Beverages"}.to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 403
    end
  end

  context "when the user is not authenticated" do
    it "returns 400" do
      space = create_space

      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:space:channel:create", space_hashed_id: space.hashed_id),
        data: {name: "Beverages"}.to_json,
        content_type: "application/json"
      )

      response.status.should eq 400
    end
  end

  context "when the user owns an unrelated space" do
    it "returns 403 and does not create a channel in the other user's space" do
      user = create_user
      create_space(manager: user)
      other_space = create_space

      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:space:channel:create", space_hashed_id: other_space.hashed_id),
        data: {name: "Beverages"}.to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 403
    end
  end

  context "when the user has OWNER role in the same organization as the space owner" do
    it "creates the channel" do
      organization = create_organization
      space_owner = create_user(organization: organization)
      space = create_space(manager: space_owner)
      colleague = create_user(organization: organization, role: Auth::Role::OWNER)

      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:space:channel:create", space_hashed_id: space.hashed_id),
        data: {name: "Beverages"}.to_json,
        headers: {authorization: "Bearer #{colleague.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 201
    end
  end
end
