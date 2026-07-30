require "./spec_helper"

describe Antrikan::QueueEstimationHandler do
  it "returns items_ahead per channel the queue has active items in" do
    channel = create_channel
    ahead = create_queue(space: channel.space!)
    create_queued_item(queue: ahead, channel: channel)

    queue = create_queue(space: channel.space!)
    create_queued_item(queue: queue, channel: channel)

    response = Marten::Spec.client.get(
      Marten.routes.reverse("antrikan:queue:estimation", queue_slug: queue.slug!)
    )

    response.status.should eq 200

    records = JSON.parse(response.content).as_a
    records.size.should eq 1
    records[0]["channel_id"].should eq channel.hashed_id
    records[0]["items_ahead"].should eq 1
  end

  it "returns an empty array when the queue has no active items" do
    queue = create_queue

    response = Marten::Spec.client.get(
      Marten.routes.reverse("antrikan:queue:estimation", queue_slug: queue.slug!)
    )

    response.status.should eq 200
    JSON.parse(response.content).as_a.should be_empty
  end

  it "returns 404 when the queue does not exist" do
    response = Marten::Spec.client.get(
      Marten.routes.reverse("antrikan:queue:estimation", queue_slug: "UNKNOWN00")
    )

    response.status.should eq 404
  end
end
