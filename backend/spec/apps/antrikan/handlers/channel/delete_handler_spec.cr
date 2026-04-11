require "./spec_helper"

describe Antrikan::ChannelDeleteHandler do
  describe "#delete" do
    context "when the user is an admin" do
      it "soft deletes the channel" do
        user = create_user
        channel = create_channel
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

    context "when the user is not an admin" do
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
end
