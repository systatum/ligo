require "./spec_helper"

describe Antrikan::ChannelShowHandler do
  describe "#get" do
    it "returns the channel" do
      channel = create_channel(name: "Beverages", description: "All drinks")

      response = Marten::Spec.client.get(
        Marten.routes.reverse("antrikan:channel:show", channel_hashed_id: channel.hashed_id)
      )

      response.status.should eq 200
      response.content.should eq Antrikan::ChannelSerializer.serialize(channel)
    end

    it "returns 404 when the channel is deleted" do
      channel = create_channel
      channel.soft_delete!

      response = Marten::Spec.client.get(
        Marten.routes.reverse("antrikan:channel:show", channel_hashed_id: channel.hashed_id)
      )

      response.status.should eq 404
    end

    it "returns 404 for a non-existent channel" do
      response = Marten::Spec.client.get(
        Marten.routes.reverse("antrikan:channel:show", channel_hashed_id: IdConcealer.encode(999999999))
      )

      response.status.should eq 404
    end
  end
end
