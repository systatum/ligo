require "./spec_helper"

describe Antrikan::ItemIndexHandler do
  it "returns all active items for the channel" do
    channel = create_channel
    item1 = create_item(channel: channel, name: "8AM", order: 0)
    item2 = create_item(channel: channel, name: "9AM", order: 1)

    response = Marten::Spec.client.get(
      Marten.routes.reverse("antrikan:channel:item:index", channel_hashed_id: channel.hashed_id)
    )

    response.status.should eq 200

    json_response = JSON.parse(response.content)
    records = json_response["items"].as_a
    records.size.should eq 2

    records[0]["id"].should eq item1.slug!
    records[0]["name"].should eq item1.name
    records[0]["order"].should eq item1.order
    records[0]["daily_cap"].should eq item1.daily_cap
    records[0]["is_monitored"].should eq item1.is_monitored
    records[0]["main_image"].should eq nil

    records[1]["id"].should eq item2.slug!
    records[1]["name"].should eq item2.name
    records[1]["order"].should eq item2.order
    records[1]["daily_cap"].should eq item2.daily_cap
    records[1]["is_monitored"].should eq item2.is_monitored
    records[1]["main_image"].should eq nil
  end

  it "returns items ordered by order field" do
    channel = create_channel
    item_b = create_item(channel: channel, name: "9AM", order: 1)
    item_a = create_item(channel: channel, name: "8AM", order: 0)

    response = Marten::Spec.client.get(
      Marten.routes.reverse("antrikan:channel:item:index", channel_hashed_id: channel.hashed_id)
    )

    response.status.should eq 200

    json_response = JSON.parse(response.content)
    records = json_response["items"].as_a

    records[0]["id"].should eq item_a.slug!
    records[1]["id"].should eq item_b.slug!
  end

  it "does not return deleted items by default" do
    channel = create_channel
    active = create_item(channel: channel, name: "8AM")
    deleted = create_item(channel: channel, name: "9AM")
    deleted.soft_delete!

    response = Marten::Spec.client.get(
      Marten.routes.reverse("antrikan:channel:item:index", channel_hashed_id: channel.hashed_id)
    )

    response.status.should eq 200

    json_response = JSON.parse(response.content)
    records = json_response["items"].as_a
    records.size.should eq 1

    records[0]["id"].should eq active.slug!
  end

  it "includes deleted items when ?with_deleted=true" do
    channel = create_channel
    active = create_item(channel: channel, name: "8AM")
    deleted = create_item(channel: channel, name: "9AM")
    deleted.soft_delete!

    response = Marten::Spec.client.get(
      Marten.routes.reverse("antrikan:channel:item:index", channel_hashed_id: channel.hashed_id),
      query_params: {with_deleted: "true"}
    )

    response.status.should eq 200

    json_response = JSON.parse(response.content)
    records = json_response["items"].as_a
    records.size.should eq 2

    item_ids = records.map { |r| r["id"].as_s }.to_set
    item_ids.should contain active.slug!
    item_ids.should contain deleted.slug!
  end

  it "does not return items from other channels" do
    channel1 = create_channel
    channel2 = create_channel
    item1 = create_item(channel: channel1, name: "8AM")
    item2 = create_item(channel: channel2, name: "9AM")

    response = Marten::Spec.client.get(
      Marten.routes.reverse("antrikan:channel:item:index", channel_hashed_id: channel1.hashed_id)
    )

    response.status.should eq 200
    response.content.should contain item1.slug!
    response.content.should_not contain item2.slug!
  end

  it "returns an empty items list when there are none" do
    channel = create_channel

    response = Marten::Spec.client.get(
      Marten.routes.reverse("antrikan:channel:item:index", channel_hashed_id: channel.hashed_id)
    )

    response.status.should eq 200
    response.content.should eq({items: [] of String}.to_json)
  end
end
