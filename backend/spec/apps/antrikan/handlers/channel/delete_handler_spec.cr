require "./spec_helper"

describe Antrikan::ChannelDeleteHandler do
  context "when the user owns the channel's space" do
    it "soft deletes the channel" do
      user = create_user
      space = create_space(manager: user)
      channel = create_channel(space: space)
      channel_id = channel.id!

      response = Marten::Spec.client.delete(
        Marten.routes.reverse("antrikan:channel:delete", channel_hashed_id: channel.hashed_id),
        headers: {authorization: "Bearer #{user.jwt_token}"}
      )

      response.status.should eq 200

      deleted = Antrikan::Channel.unscoped.get!(id: channel_id)
      deleted.deleted_at.should be_a Time

      response.content.should eq Antrikan::ChannelSerializer.serialize(deleted)
    end
  end

  context "when the user has an insufficient role and does not own the space" do
    it "returns 403 and does not delete the channel" do
      user = create_user(role: Auth::Role::SECURITY_STAFF)
      channel = create_channel

      response = Marten::Spec.client.delete(
        Marten.routes.reverse("antrikan:channel:delete", channel_hashed_id: channel.hashed_id),
        headers: {authorization: "Bearer #{user.jwt_token}"}
      )

      response.status.should eq 403

      channel.reload
      channel.deleted_at.should be_nil
    end
  end

  context "when the user owns an unrelated space" do
    it "returns 403 and does not delete the channel" do
      user = create_user
      create_space(manager: user)
      channel = create_channel

      response = Marten::Spec.client.delete(
        Marten.routes.reverse("antrikan:channel:delete", channel_hashed_id: channel.hashed_id),
        headers: {authorization: "Bearer #{user.jwt_token}"}
      )

      response.status.should eq 403

      channel.reload
      channel.deleted_at.should be_nil
    end
  end

  context "when the user has OWNER role in the same organization as the space owner" do
    it "deletes the channel" do
      organization = create_organization
      space_owner = create_user(organization: organization)
      space = create_space(manager: space_owner)
      channel = create_channel(space: space)
      channel_id = channel.id!
      colleague = create_user(organization: organization, role: Auth::Role::OWNER)

      response = Marten::Spec.client.delete(
        Marten.routes.reverse("antrikan:channel:delete", channel_hashed_id: channel.hashed_id),
        headers: {authorization: "Bearer #{colleague.jwt_token}"}
      )

      response.status.should eq 200

      deleted = Antrikan::Channel.unscoped.get!(id: channel_id)
      deleted.deleted_at.should be_a Time
    end
  end

  context "when the user is not authenticated" do
    it "returns 400 and does not delete the channel" do
      channel = create_channel

      response = Marten::Spec.client.delete(
        Marten.routes.reverse("antrikan:channel:delete", channel_hashed_id: channel.hashed_id)
      )

      response.status.should eq 400

      channel.reload
      channel.deleted_at.should be_nil
    end
  end
end
