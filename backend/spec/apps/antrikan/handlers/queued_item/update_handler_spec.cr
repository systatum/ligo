require "./spec_helper"

describe Antrikan::QueuedItemUpdateHandler do
  context "when the request payload is valid" do
    it "updates allowed fields" do
      ctx = create_authorized_queue_item(note: "old")

      response = Marten::Spec.client.patch(
        Marten.routes.reverse(
          "antrikan:queue:item:update",
          queue_slug: ctx[:queue].slug!,
          queued_item_slug: ctx[:queued_item].slug!
        ),
        data: {
          handler_id: ctx[:user].hashed_id,
          status:     Antrikan::QueueStatus::READY,
          note:       "updated",
        }.to_json,
        headers: {authorization: "Bearer #{ctx[:user].jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 200

      ctx[:queued_item].reload
      ctx[:queued_item].handler_id.should eq ctx[:user].id
      ctx[:queued_item].status.should eq Antrikan::QueueStatus::READY.value
      ctx[:queued_item].note.should eq "updated"

      response.content.should eq Antrikan::QueuedItemSerializer.serialize(ctx[:queued_item])
    end

    it "soft-deletes queued item when applying CANCELED status" do
      ctx = create_authorized_queue_item

      response = Marten::Spec.client.patch(
        Marten.routes.reverse(
          "antrikan:queue:item:update",
          queue_slug: ctx[:queue].slug!,
          queued_item_slug: ctx[:queued_item].slug!
        ),
        data: {
          status: Antrikan::QueueStatus::CANCELED,
        }.to_json,
        headers: {authorization: "Bearer #{ctx[:user].jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 200

      deleted_queued_item = Antrikan::QueuedItem.unscoped.get!(id: ctx[:queued_item].id)
      deleted_queued_item.status.should eq Antrikan::QueueStatus::CANCELED.value
      deleted_queued_item.deleted_at.should_not be_nil

      response.content.should eq Antrikan::QueuedItemSerializer.serialize(deleted_queued_item)
    end
  end

  context "when the request payload is invalid" do
    it "rejects unauthenticated request" do
      queue = create_queue
      queued_item = create_queued_item(queue: queue, item: create_item(channel: queue.channel!))

      response = Marten::Spec.client.patch(
        Marten.routes.reverse(
          "antrikan:queue:item:update",
          queue_slug: queued_item.queue!.slug!,
          queued_item_slug: queued_item.slug!
        ),
        data: {
          status: Antrikan::QueueStatus::DONE,
        }.to_json,
        content_type: "application/json"
      )

      response.status.should eq 403
    end

    it "rejects authenticated user from different organization" do
      organization = create_organization
      owner = create_user(organization: organization)
      space = create_space(owner: owner)
      channel = create_channel(space: space)
      queue = create_queue(channel: channel, queuer: create_queuer(space: space))
      queued_item = create_queued_item(queue: queue, item: create_item(channel: channel))

      outsider = create_user(organization: create_organization)

      response = Marten::Spec.client.patch(
        Marten.routes.reverse(
          "antrikan:queue:item:update",
          queue_slug: queued_item.queue!.slug!,
          queued_item_slug: queued_item.slug!
        ),
        data: {
          note: "unauthorized",
        }.to_json,
        headers: {authorization: "Bearer #{outsider.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 403

      queued_item.reload
      queued_item.note.should_not eq "unauthorized"
    end

    it "returns 422 when trying to update forbidden fields" do
      ctx = create_authorized_queue_item
      ctx[:queued_item].unit_price = 10_000_i64
      ctx[:queued_item].quantity = 2
      ctx[:queued_item].save!

      response = Marten::Spec.client.patch(
        Marten.routes.reverse(
          "antrikan:queue:item:update",
          queue_slug: ctx[:queued_item].queue!.slug!,
          queued_item_slug: ctx[:queued_item].slug!
        ),
        data: {
          unit_price: 50_000,
          quantity:   100,
        }.to_json,
        headers: {authorization: "Bearer #{ctx[:user].jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 422

      ctx[:queued_item].reload
      ctx[:queued_item].unit_price.should eq 10_000_i64
      ctx[:queued_item].quantity.should eq 2
    end

    it "returns 404 when queued item does not belong to the queue slug" do
      organization = create_organization
      owner = create_user(organization: organization)
      space = create_space(owner: owner)
      channel = create_channel(space: space)
      other_channel = create_channel(space: space, name: "Other")
      queue_a = create_queue(channel: channel, queuer: create_queuer(space: space))
      queue_b = create_queue(channel: other_channel, queuer: create_queuer(space: space))
      queued_item = create_queued_item(queue: queue_b, item: create_item(channel: other_channel))

      user = create_user(organization: organization)

      response = Marten::Spec.client.patch(
        Marten.routes.reverse(
          "antrikan:queue:item:update",
          queue_slug: queue_a.slug!,
          queued_item_slug: queued_item.slug!
        ),
        data: {
          note: "wrong queue",
        }.to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 404
    end

    it "returns 404 when queued item does not exist" do
      ctx = create_authorized_queue_item

      response = Marten::Spec.client.patch(
        Marten.routes.reverse(
          "antrikan:queue:item:update",
          queue_slug: ctx[:queue].slug!,
          queued_item_slug: "UNKNOWN00"
        ),
        data: {note: "x"}.to_json,
        headers: {authorization: "Bearer #{ctx[:user].jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 404
    end

    it "returns 404 when handler_id does not exist" do
      ctx = create_authorized_queue_item

      response = Marten::Spec.client.patch(
        Marten.routes.reverse(
          "antrikan:queue:item:update",
          queue_slug: ctx[:queue].slug!,
          queued_item_slug: ctx[:queued_item].slug!
        ),
        data: {
          handler_id: IdConcealer.encode(9_999_999),
        }.to_json,
        headers: {authorization: "Bearer #{ctx[:user].jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 404

      ctx[:queued_item].reload
      ctx[:queued_item].handler_id.should be_nil
    end

    it "forbids regressing status from READY to QUEUED" do
      ctx = create_authorized_queue_item(status: Antrikan::QueueStatus::READY)

      response = Marten::Spec.client.patch(
        Marten.routes.reverse(
          "antrikan:queue:item:update",
          queue_slug: ctx[:queue].slug!,
          queued_item_slug: ctx[:queued_item].slug!
        ),
        data: {
          status: Antrikan::QueueStatus::QUEUED,
        }.to_json,
        headers: {authorization: "Bearer #{ctx[:user].jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 422

      ctx[:queued_item].reload
      ctx[:queued_item].status.should eq Antrikan::QueueStatus::READY.value
    end

    it "forbids regressing status from DONE to DISPATCHING" do
      ctx = create_authorized_queue_item(status: Antrikan::QueueStatus::DONE)

      response = Marten::Spec.client.patch(
        Marten.routes.reverse(
          "antrikan:queue:item:update",
          queue_slug: ctx[:queue].slug!,
          queued_item_slug: ctx[:queued_item].slug!
        ),
        data: {
          status: Antrikan::QueueStatus::DISPATCHING,
        }.to_json,
        headers: {authorization: "Bearer #{ctx[:user].jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 422

      ctx[:queued_item].reload
      ctx[:queued_item].status.should eq Antrikan::QueueStatus::DONE.value
    end

    it "returns 422 for unknown status event" do
      ctx = create_authorized_queue_item

      response = Marten::Spec.client.patch(
        Marten.routes.reverse(
          "antrikan:queue:item:update",
          queue_slug: ctx[:queue].slug!,
          queued_item_slug: ctx[:queued_item].slug!
        ),
        data: {
          status: "noop",
        }.to_json,
        headers: {authorization: "Bearer #{ctx[:user].jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 422

      ctx[:queued_item].reload
      ctx[:queued_item].status.should eq Antrikan::QueueStatus::QUEUED.value
    end
  end
end
