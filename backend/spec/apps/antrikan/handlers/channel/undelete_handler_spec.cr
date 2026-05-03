require "./spec_helper"

describe Antrikan::ChannelUndeleteHandler do
  context "when the user is an admin" do
    it "restores a deleted channel" do
      user = create_user
      channel = create_channel
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

  context "when the user is not an admin" do
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
