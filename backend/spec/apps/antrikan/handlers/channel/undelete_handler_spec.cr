require "./spec_helper"

describe Antrikan::ChannelUndeleteHandler do
  context "when the user owns the channel's space" do
    it "restores a deleted channel" do
      user = create_user
      space = create_space(manager: user)
      channel = create_channel(space: space)
      channel.soft_delete!
      channel_id = channel.id!

      response = Marten::Spec.client.patch(
        Marten.routes.reverse("antrikan:channel:undelete", channel_hashed_id: channel.hashed_id),
        headers: {authorization: "Bearer #{user.jwt_token}"}
      )

      response.status.should eq 200

      restored = Antrikan::Channel.get!(id: channel_id)
      restored.deleted_at.should be_nil

      response.content.should eq Antrikan::ChannelSerializer.serialize(restored)
    end
  end

  context "when the user has an insufficient role and does not own the space" do
    it "returns 403 and does not restore the channel" do
      user = create_user(role: Auth::Role::SECURITY_STAFF)
      channel = create_channel
      channel.soft_delete!

      response = Marten::Spec.client.patch(
        Marten.routes.reverse("antrikan:channel:undelete", channel_hashed_id: channel.hashed_id),
        headers: {authorization: "Bearer #{user.jwt_token}"}
      )

      response.status.should eq 403

      channel_in_db = Antrikan::Channel.unscoped.get!(id: channel.id!)
      channel_in_db.deleted_at.should_not be_nil
    end
  end

  context "when the user owns an unrelated space" do
    it "returns 403 and does not restore the channel" do
      user = create_user
      create_space(manager: user)
      channel = create_channel
      channel.soft_delete!

      response = Marten::Spec.client.patch(
        Marten.routes.reverse("antrikan:channel:undelete", channel_hashed_id: channel.hashed_id),
        headers: {authorization: "Bearer #{user.jwt_token}"}
      )

      response.status.should eq 403

      channel_in_db = Antrikan::Channel.unscoped.get!(id: channel.id!)
      channel_in_db.deleted_at.should_not be_nil
    end
  end

  context "when the user has OWNER role in the same organization as the space owner" do
    it "restores the channel" do
      organization = create_organization
      space_owner = create_user(organization: organization)
      space = create_space(manager: space_owner)
      channel = create_channel(space: space)
      channel.soft_delete!
      colleague = create_user(organization: organization, role: Auth::Role::OWNER)

      response = Marten::Spec.client.patch(
        Marten.routes.reverse("antrikan:channel:undelete", channel_hashed_id: channel.hashed_id),
        headers: {authorization: "Bearer #{colleague.jwt_token}"}
      )

      response.status.should eq 200

      channel.reload
      channel.deleted_at.should be_nil
    end
  end

  context "when the user is not authenticated" do
    it "returns 400" do
      channel = create_channel
      channel.soft_delete!

      response = Marten::Spec.client.patch(
        Marten.routes.reverse("antrikan:channel:undelete", channel_hashed_id: channel.hashed_id)
      )

      response.status.should eq 400
    end
  end
end
