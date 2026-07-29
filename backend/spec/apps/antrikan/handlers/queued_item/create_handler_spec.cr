require "./spec_helper"

describe Antrikan::QueuedItemCreateHandler do
  context "when the request payload is valid" do
    it "creates queued item with required fields" do
      queue = create_queue
      item = create_item(channel: create_channel(space: queue.space!))

      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:queue:item:create", queue_slug: queue.slug!),
        data: {
          item_slug: item.slug,
        }.to_json,
        content_type: "application/json"
      )

      response.status.should eq 201

      queued_item = Antrikan::QueuedItem.last!
      queued_item.id.should_not be_nil
      queued_item.queue_id.should eq queue.id
      queued_item.channel_id.should eq item.channel_id
      queued_item.item_id.should eq item.id
      queued_item.status.should eq Antrikan::QueueStatus::QUEUED.value
      queued_item.quantity.should eq 1

      response.content.should eq Antrikan::QueuedItemSerializer.serialize(queued_item)
    end

    it "accepts optional fields" do
      queue = create_queue
      item = create_item(channel: create_channel(space: queue.space!))
      user = create_user(organization: queue.queuer!.space!.manager!.organization!)

      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:queue:item:create", queue_slug: queue.slug!),
        data: {
          item_slug:  item.slug,
          handler_id: user.hashed_id,
          status:     Antrikan::QueueStatus::ATTENDED,
          note:       "extra spicy",
          quantity:   2,
        }.to_json,
        content_type: "application/json"
      )

      response.status.should eq 201

      queued_item = Antrikan::QueuedItem.last!
      queued_item.handler_id.should eq user.id
      queued_item.status.should eq Antrikan::QueueStatus::ATTENDED.value
      queued_item.note.should eq "extra spicy"
      queued_item.quantity.should eq 2

      response.content.should eq Antrikan::QueuedItemSerializer.serialize(queued_item)
    end

    it "creates a new record even when same item is added repeatedly" do
      queue = create_queue
      item = create_item(channel: create_channel(space: queue.space!))
      path = Marten.routes.reverse("antrikan:queue:item:create", queue_slug: queue.slug!)

      first = Marten::Spec.client.post(
        path,
        data: {
          item_slug: item.slug,
        }.to_json,
        content_type: "application/json"
      )
      first.status.should eq 201

      second = Marten::Spec.client.post(
        path,
        data: {
          item_slug: item.slug,
        }.to_json,
        content_type: "application/json"
      )
      second.status.should eq 201

      first_parsed = JSON.parse(first.content)
      second_parsed = JSON.parse(second.content)
      first_parsed["id"].as_s.should_not eq second_parsed["id"].as_s
    end

    it "allows creating with non-queued status (state jump)" do
      queue = create_queue
      item = create_item(channel: create_channel(space: queue.space!))

      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:queue:item:create", queue_slug: queue.slug!),
        data: {
          item_slug: item.slug,
          status:    Antrikan::QueueStatus::DONE,
        }.to_json,
        content_type: "application/json"
      )

      response.status.should eq 201

      queued_item = Antrikan::QueuedItem.last!
      queued_item.status.should eq Antrikan::QueueStatus::DONE.value

      response.content.should eq Antrikan::QueuedItemSerializer.serialize(queued_item)
    end

    it "soft-deletes queued item when creating with CANCELED status" do
      queue = create_queue
      item = create_item(channel: create_channel(space: queue.space!))

      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:queue:item:create", queue_slug: queue.slug!),
        data: {
          item_slug: item.slug,
          status:    Antrikan::QueueStatus::CANCELED,
        }.to_json,
        content_type: "application/json"
      )

      response.status.should eq 201

      queued_item = Antrikan::QueuedItem.unscoped.last!
      queued_item.queue_id.should eq queue.id
      queued_item.item_id.should eq item.id
      queued_item.status.should eq Antrikan::QueueStatus::CANCELED.value
      queued_item.deleted_at.should_not be_nil

      response.content.should eq Antrikan::QueuedItemSerializer.serialize(queued_item)
    end

    it "accepts an item from a different channel within the same space as the queue" do
      space = create_space
      queue = create_queue(space: space)
      other_channel = create_channel(space: space)
      item = create_item(channel: other_channel)

      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:queue:item:create", queue_slug: queue.slug!),
        data: {
          item_slug: item.slug,
        }.to_json,
        content_type: "application/json"
      )

      response.status.should eq 201

      queued_item = Antrikan::QueuedItem.last!
      queued_item.channel_id.should eq other_channel.id
    end
  end

  context "when the request payload is invalid" do
    it "returns 422 when required fields are missing" do
      queue = create_queue

      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:queue:item:create", queue_slug: queue.slug!),
        data: {
          note: "missing item",
        }.to_json,
        content_type: "application/json"
      )

      response.status.should eq 422
    end

    it "returns 404 when queue does not exist" do
      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:queue:item:create", queue_slug: "UNKNOWN00"),
        data: {
          item_slug: "ABC123",
        }.to_json,
        content_type: "application/json"
      )

      response.status.should eq 404
    end

    it "returns 422 when cancel_note is provided on create" do
      queue = create_queue
      item = create_item(channel: create_channel(space: queue.space!))

      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:queue:item:create", queue_slug: queue.slug!),
        data: {
          item_slug:   item.slug,
          cancel_note: "not allowed on create",
        }.to_json,
        content_type: "application/json"
      )

      response.status.should eq 422
    end

    it "returns 422 when the item's channel belongs to a different space than the queue" do
      queue = create_queue
      other_channel = create_channel
      item = create_item(channel: other_channel)

      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:queue:item:create", queue_slug: queue.slug!),
        data: {
          item_slug: item.slug,
        }.to_json,
        content_type: "application/json"
      )

      response.status.should eq 422
    end

    it "returns 422 when the channel's max_item_piece is already reached" do
      channel = create_channel(max_item_piece: 1)
      queue = create_queue(space: channel.space!)
      item = create_item(channel: channel)
      create_queued_item(queue: queue, item: item, channel: channel)

      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:queue:item:create", queue_slug: queue.slug!),
        data: {
          item_slug: item.slug,
        }.to_json,
        content_type: "application/json"
      )

      response.status.should eq 422
    end

    it "returns 422 when the queue is already paid" do
      queue = create_queue(payment_status: Antrikan::PaymentStatus::PARTIAL)
      item = create_item(channel: create_channel(space: queue.space!))

      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:queue:item:create", queue_slug: queue.slug!),
        data: {
          item_slug: item.slug,
        }.to_json,
        content_type: "application/json"
      )

      response.status.should eq 422
    end
  end
end
