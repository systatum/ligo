require "./spec_helper"

describe Antrikan::QueuedItemUpdateHandler do
  context "when the request payload is valid" do
    it "updates a single item" do
      ctx = create_authorized_queue_item(note: "old")
      qi = ctx[:queued_item]
      user = ctx[:user]

      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:queued_item:update"),
        data: {items: [
          {
            id:     qi.id.to_s,
            status: Antrikan::QueueStatus::ATTENDED,
            note:   "updated",
          },
        ]}.to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 200

      qi.reload
      response.content.should eq({items: [Antrikan::QueuedItemSerializer.soft_serialize(qi)]}.to_json)
    end

    it "updates multiple items at once" do
      ctx = create_authorized_queue_item
      queue = ctx[:queue]
      user = ctx[:user]
      qi_a = ctx[:queued_item]
      qi_b = create_queued_item(queue: queue, item: create_item(channel: queue.channel!))

      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:queued_item:update"),
        data: {items: [
          {id: qi_a.id.to_s, status: Antrikan::QueueStatus::ATTENDED, note: "first"},
          {id: qi_b.id.to_s, status: Antrikan::QueueStatus::PACKED, note: "second"},
        ]}.to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 200

      qi_a.reload
      qi_b.reload
      response.content.should eq(
        {items: [
          Antrikan::QueuedItemSerializer.soft_serialize(qi_a),
          Antrikan::QueuedItemSerializer.soft_serialize(qi_b),
        ]}.to_json
      )
    end

    it "assigns handler when handler_id is provided" do
      ctx = create_authorized_queue_item
      qi = ctx[:queued_item]
      user = ctx[:user]
      handler = create_user(organization: ctx[:organization])

      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:queued_item:update"),
        data: {items: [
          {id: qi.id.to_s, handler_id: handler.id.to_s},
        ]}.to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 200

      qi.reload
      response.content.should eq({items: [Antrikan::QueuedItemSerializer.soft_serialize(qi)]}.to_json)
    end

    it "soft-deletes when applying CANCELED status" do
      ctx = create_authorized_queue_item
      qi = ctx[:queued_item]
      user = ctx[:user]

      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:queued_item:update"),
        data: {items: [
          {id: qi.id.to_s, status: Antrikan::QueueStatus::CANCELED},
        ]}.to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 200

      deleted_qi = Antrikan::QueuedItem.unscoped.get!(id: qi.id)
      response.content.should eq({items: [Antrikan::QueuedItemSerializer.soft_serialize(deleted_qi)]}.to_json)
    end
  end

  context "when the request payload is invalid" do
    it "rejects unauthenticated request" do
      qi = create_queued_item

      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:queued_item:update"),
        data: {items: [
          {id: qi.id.to_s, note: "x"},
        ]}.to_json,
        content_type: "application/json"
      )

      response.status.should eq 403
    end

    it "rejects user from different organization" do
      ctx = create_authorized_queue_item
      qi = ctx[:queued_item]
      outsider = create_user(organization: create_organization)

      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:queued_item:update"),
        data: {items: [
          {id: qi.id.to_s, note: "unauthorized"},
        ]}.to_json,
        headers: {authorization: "Bearer #{outsider.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 403
    end

    it "returns 422 when items array is empty" do
      user = create_user

      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:queued_item:update"),
        data: %({"items": []}),
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 422
    end

    it "returns 422 when an item is not found" do
      user = create_user

      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:queued_item:update"),
        data: {items: [
          {id: UUID.random.to_s, note: "x"},
        ]}.to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 422
    end

    it "returns 422 for invalid status transition" do
      ctx = create_authorized_queue_item(status: Antrikan::QueueStatus::DONE)
      qi = ctx[:queued_item]
      user = ctx[:user]

      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:queued_item:update"),
        data: {items: [
          {id: qi.id.to_s, status: Antrikan::QueueStatus::QUEUED},
        ]}.to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 422

      qi.reload
      qi.status.should eq Antrikan::QueueStatus::DONE.value
    end
  end
end
