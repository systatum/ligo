require "./spec_helper"

describe Antrikan::QueuedItemIndexHandler do
  it "returns queued items ordered by rank then created_at" do
    cid = create_channel
    queue = create_queue(space: cid.space!)
    qi1 = create_queued_item(queue: queue, item: create_item(channel: cid), rank: 2)
    qi2 = create_queued_item(queue: queue, item: create_item(channel: cid), rank: 1)
    qi3 = create_queued_item(queue: queue, item: create_item(channel: cid), rank: 1)

    response = Marten::Spec.client.get(
      Marten.routes.reverse("antrikan:queue:items_index", queue_slug: queue.slug!)
    )

    response.status.should eq 200

    json_response = JSON.parse(response.content)
    records = json_response["items"].as_a
    records.size.should eq 3

    records[0]["id"].should eq qi2.id.to_s
    records[1]["id"].should eq qi3.id.to_s
    records[2]["id"].should eq qi1.id.to_s
  end

  it "scopes items to the requested queue" do
    cid_a = create_channel
    cid_b = create_channel
    queue_a = create_queue(space: cid_a.space!)
    queue_b = create_queue(space: cid_b.space!)
    qi_a = create_queued_item(queue: queue_a, item: create_item(channel: cid_a))
    create_queued_item(queue: queue_b, item: create_item(channel: cid_b))

    response = Marten::Spec.client.get(
      Marten.routes.reverse("antrikan:queue:items_index", queue_slug: queue_a.slug!)
    )

    response.status.should eq 200

    json_response = JSON.parse(response.content)
    records = json_response["items"].as_a
    records.size.should eq 1
    records[0]["id"].should eq qi_a.id.to_s
  end

  it "returns 404 when queue does not exist" do
    response = Marten::Spec.client.get(
      Marten.routes.reverse("antrikan:queue:items_index", queue_slug: "UNKNOWN00")
    )

    response.status.should eq 404
  end

  it "returns empty list when queue has no items" do
    queue = create_queue

    response = Marten::Spec.client.get(
      Marten.routes.reverse("antrikan:queue:items_index", queue_slug: queue.slug!)
    )

    response.status.should eq 200

    json_response = JSON.parse(response.content)
    json_response["items"].as_a.size.should eq 0
  end
end
