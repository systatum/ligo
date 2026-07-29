require "./spec_helper"

describe Antrikan::ChannelIndexHandler do
  it "returns all active channels for the space" do
    space = create_space
    ch1 = create_channel(space: space, name: "Beverages")
    ch2 = create_channel(space: space, name: "Noodles")

    response = Marten::Spec.client.get(
      Marten.routes.reverse("antrikan:space:channel:index", space_hashed_id: space.hashed_id)
    )

    response.status.should eq 200

    json_response = JSON.parse(response.content)
    records = json_response.as_a
    records.size.should eq 2

    records[0]["id"].should eq ch1.hashed_id
    records[0]["name"].should eq ch1.name
    records[0]["description"].should eq ch1.description
    records[0]["logo"].should eq nil

    records[1]["id"].should eq ch2.hashed_id
    records[1]["name"].should eq ch2.name
    records[1]["description"].should eq ch2.description
    records[1]["logo"].should eq nil
  end

  it "does not return deleted channels by default" do
    space = create_space
    active = create_channel(space: space, name: "Beverages")
    deleted = create_channel(space: space, name: "Noodles")
    deleted.soft_delete!

    response = Marten::Spec.client.get(
      Marten.routes.reverse("antrikan:space:channel:index", space_hashed_id: space.hashed_id)
    )

    response.status.should eq 200

    json_response = JSON.parse(response.content)
    records = json_response.as_a
    records.size.should eq 1

    records[0]["id"].should eq active.hashed_id
    records[0]["name"].should eq active.name
    records[0]["description"].should eq active.description
    records[0]["logo"].should eq nil
  end

  it "includes deleted channels when ?with_deleted=true" do
    space = create_space
    active = create_channel(space: space, name: "Beverages")
    deleted = create_channel(space: space, name: "Noodles")
    deleted.soft_delete!

    response = Marten::Spec.client.get(
      Marten.routes.reverse("antrikan:space:channel:index", space_hashed_id: space.hashed_id),
      query_params: {with_deleted: "true"}
    )

    response.status.should eq 200

    json_response = JSON.parse(response.content)
    records = json_response.as_a
    records.size.should eq 2

    channel_ids = records.map { |r| r["id"].as_s }.to_set
    channel_ids.should contain active.hashed_id
    channel_ids.should contain deleted.hashed_id
  end

  it "does not return channels from other spaces" do
    space1 = create_space
    space2 = create_space
    ch1 = create_channel(space: space1, name: "Beverages")
    ch2 = create_channel(space: space2, name: "Noodles")

    response = Marten::Spec.client.get(
      Marten.routes.reverse("antrikan:space:channel:index", space_hashed_id: space1.hashed_id)
    )

    response.status.should eq 200
    response.content.should contain ch1.hashed_id
    response.content.should_not contain ch2.hashed_id
  end

  it "returns an empty channels list when there are none" do
    space = create_space

    response = Marten::Spec.client.get(
      Marten.routes.reverse("antrikan:space:channel:index", space_hashed_id: space.hashed_id)
    )

    response.status.should eq 200
    response.content.should eq(([] of String).to_json)
  end
end
