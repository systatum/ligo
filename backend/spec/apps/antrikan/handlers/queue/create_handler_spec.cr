require "./spec_helper"

describe Antrikan::QueueCreateHandler do
  context "when the request payload is valid" do
    it "creates a queue with required fields only" do
      channel = create_channel
      queuer = create_queuer(space: channel.space.not_nil!)

      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:channel:queue:create", channel_hashed_id: channel.hashed_id),
        data: {
          queuer_id: queuer.hashed_id,
        }.to_json,
        content_type: "application/json"
      )

      response.status.should eq 201

      queue = Antrikan::Queue.last!
      queue.id.should_not be_nil
      queue.channel_id.should eq channel.id
      queue.queuer_id.should eq queuer.id
      queue.status.should eq Antrikan::QueueStatus::QUEUED.value
      queue.payment_status.should eq Antrikan::PaymentStatus::UNPAID.value
      queue.total_price.should eq 0_i64

      response.content.should eq Antrikan::QueueSerializer.serialize(queue)
    end

    it "accepts optional fields" do
      channel = create_channel
      queuer = create_queuer(space: channel.space.not_nil!)
      user = create_user(organization: channel.space.not_nil!.manager.not_nil!.organization.not_nil!)

      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:channel:queue:create", channel_hashed_id: channel.hashed_id),
        data: {
          queuer_id:      queuer.hashed_id,
          handler_id:     user.hashed_id,
          note:           "we accept optional fields",
          payment_status: Antrikan::PaymentStatus::PARTIAL,
          fully_paid_at:  "2026-05-23T10:15:00Z",
        }.to_json,
        content_type: "application/json"
      )

      response.status.should eq 201

      queue = Antrikan::Queue.last!
      queue.channel_id.should eq channel.id
      queue.handler_id.should eq user.id
      queue.note.should eq "we accept optional fields"
      queue.status.should eq Antrikan::QueueStatus::QUEUED.value
      queue.payment_status.should eq Antrikan::PaymentStatus::PARTIAL.value
      queue.fully_paid_at.not_nil!.to_rfc3339.should eq "2026-05-23T10:15:00Z"

      response.content.should eq Antrikan::QueueSerializer.serialize(queue)
    end

    it "allows creating with non-queued status (state jump)" do
      channel = create_channel
      queuer = create_queuer(space: channel.space.not_nil!)

      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:channel:queue:create", channel_hashed_id: channel.hashed_id),
        data: {
          queuer_id: queuer.hashed_id,
          status:    Antrikan::QueueStatus::DONE,
        }.to_json,
        content_type: "application/json"
      )

      response.status.should eq 201

      queue = Antrikan::Queue.last!
      queue.channel_id.should eq channel.id
      queue.queuer_id.should eq queuer.id
      queue.status.should eq Antrikan::QueueStatus::DONE.value

      response.content.should eq Antrikan::QueueSerializer.serialize(queue)
    end

    it "soft-deletes queue when creating with CANCELED status" do
      channel = create_channel
      queuer = create_queuer(space: channel.space.not_nil!)

      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:channel:queue:create", channel_hashed_id: channel.hashed_id),
        data: {
          queuer_id: queuer.hashed_id,
          status:    Antrikan::QueueStatus::CANCELED,
        }.to_json,
        content_type: "application/json"
      )

      response.status.should eq 201

      queue = Antrikan::Queue.unscoped.last!
      queue.channel_id.should eq channel.id
      queue.queuer_id.should eq queuer.id
      queue.status.should eq Antrikan::QueueStatus::CANCELED.value
      queue.deleted_at.should_not be_nil

      response.content.should eq Antrikan::QueueSerializer.serialize(queue)
    end
  end

  context "when the request payload is invalid" do
    it "returns 422 when queuer_id is missing" do
      channel = create_channel

      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:channel:queue:create", channel_hashed_id: channel.hashed_id),
        data: {
          note: "no queuer",
        }.to_json,
        content_type: "application/json"
      )

      response.status.should eq 422
    end

    it "returns 404 when channel does not exist" do
      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:channel:queue:create", channel_hashed_id: IdConcealer.encode(9_999_999)),
        data: {
          queuer_id: IdConcealer.encode(1),
        }.to_json,
        content_type: "application/json"
      )

      response.status.should eq 404
    end

    it "returns 422 when handler's organization does not match space owner's" do
      channel = create_channel
      queuer = create_queuer(space: channel.space.not_nil!)

      other_org = create_organization
      other_user = create_user(organization: other_org)

      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:channel:queue:create", channel_hashed_id: channel.hashed_id),
        data: {
          queuer_id:  queuer.hashed_id,
          handler_id: other_user.hashed_id,
        }.to_json,
        content_type: "application/json"
      )

      response.status.should eq 422
    end

    it "throttles repeated create attempts by ip and queuer_id" do
      channel = create_channel
      queuer = create_queuer(space: channel.space.not_nil!)
      path = Marten.routes.reverse("antrikan:channel:queue:create", channel_hashed_id: channel.hashed_id)

      3.times do
        response = Marten::Spec.client.post(
          path,
          data: {
            queuer_id: queuer.hashed_id,
          }.to_json,
          content_type: "application/json"
        )

        response.status.should eq 201
      end

      blocked = Marten::Spec.client.post(
        path,
        data: {
          queuer_id: queuer.hashed_id,
        }.to_json,
        content_type: "application/json"
      )

      blocked.status.should eq 429
    end

    it "does not throttle a different queuer_id on the same ip bucket" do
      channel = create_channel
      queuer_a = create_queuer(space: channel.space.not_nil!)
      queuer_b = create_queuer(space: channel.space.not_nil!)
      path = Marten.routes.reverse("antrikan:channel:queue:create", channel_hashed_id: channel.hashed_id)

      3.times do
        response = Marten::Spec.client.post(
          path,
          data: {
            queuer_id: queuer_a.hashed_id,
          }.to_json,
          content_type: "application/json"
        )

        response.status.should eq 201
      end

      response = Marten::Spec.client.post(
        path,
        data: {
          queuer_id: queuer_b.hashed_id,
        }.to_json,
        content_type: "application/json"
      )

      response.status.should eq 201
    end
  end
end
