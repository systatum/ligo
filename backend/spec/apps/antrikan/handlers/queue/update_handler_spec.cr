require "./spec_helper"

describe Antrikan::QueueUpdateHandler do
  context "when the request payload is valid" do
    it "updates allowed fields only" do
      queue = create_queue(note: "old", status: Antrikan::QueueStatus::QUEUED)
      user = create_user(organization: queue.channel!.space!.manager!.organization!)

      response = Marten::Spec.client.patch(
        Marten.routes.reverse("antrikan:queue:update", queue_slug: queue.slug!),
        data: {
          handler_id:     user.hashed_id,
          note:           "updated",
          status:         Antrikan::QueueStatus::ATTENDED,
          payment_status: Antrikan::PaymentStatus::FULL,
          fully_paid_at:  "2026-05-23T12:00:00Z",
        }.to_json,
        content_type: "application/json"
      )

      response.status.should eq 200

      queue.reload
      queue.handler_id.should eq user.id
      queue.note.should eq "updated"
      queue.status.should eq Antrikan::QueueStatus::ATTENDED.value
      queue.payment_status.should eq Antrikan::PaymentStatus::FULL.value
      queue.fully_paid_at.should_not be_nil

      response.content.should eq Antrikan::QueueSerializer.serialize(queue)
    end

    it "soft-deletes queue when applying CANCELED status" do
      queue = create_queue(status: Antrikan::QueueStatus::QUEUED)

      response = Marten::Spec.client.patch(
        Marten.routes.reverse("antrikan:queue:update", queue_slug: queue.slug!),
        data: {
          status: Antrikan::QueueStatus::CANCELED,
        }.to_json,
        content_type: "application/json"
      )

      response.status.should eq 200

      queue = Antrikan::Queue.unscoped.get!(id: queue.id!)
      queue.status.should eq Antrikan::QueueStatus::CANCELED.value
      queue.deleted_at.should_not be_nil

      response.content.should eq Antrikan::QueueSerializer.serialize(queue)
    end
  end

  context "when supplying voucher_code" do
    it "attaches the voucher and applies pay-time discounts when the space owner sets payment_status" do
      organization = create_organization
      owner = create_user(organization: organization)
      space = create_space(manager: owner)
      channel = create_channel(space: space)
      item = create_item(channel: channel)
      queue = create_queue(channel: channel, queuer: create_queuer(space: space))
      queued_item = create_queued_item(queue: queue, item: item, unit_price: 100_i64)
      voucher = create_voucher(space: space, code: "TENOFF", space_percentage_discount: 10.0)

      response = Marten::Spec.client.patch(
        Marten.routes.reverse("antrikan:queue:update", queue_slug: queue.slug!),
        data: {
          voucher_code:   voucher.code,
          payment_status: Antrikan::PaymentStatus::FULL,
        }.to_json,
        headers: {authorization: "Bearer #{owner.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 200

      Antrikan::AppliedVoucher.filter(queue_id: queue.id!).exists?.should be_true

      queued_item.reload
      queued_item.applied_voucher_ids.not_nil!.ids.size.should eq 1

      queue.reload
      queue.total_price.should eq "90.0"
    end

    it "rejects when the requester is not the space owner" do
      space = create_space
      queue = create_queue(channel: create_channel(space: space), queuer: create_queuer(space: space))
      voucher = create_voucher(space: space, code: "TENOFF", space_percentage_discount: 10.0)
      outsider = create_user

      response = Marten::Spec.client.patch(
        Marten.routes.reverse("antrikan:queue:update", queue_slug: queue.slug!),
        data: {
          voucher_code: voucher.code,
        }.to_json,
        headers: {authorization: "Bearer #{outsider.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 422
      Antrikan::AppliedVoucher.filter(queue_id: queue.id!).exists?.should be_false
    end
  end

  context "when the request payload is invalid" do
    it "does not update disallowed fields" do
      queue = create_queue(total_price: BigFloat.new(33_000))

      response = Marten::Spec.client.patch(
        Marten.routes.reverse("antrikan:queue:update", queue_slug: queue.slug!),
        data: {
          total_price: 99_000,
          queuer_id:   IdConcealer.encode(123),
        }.to_json,
        content_type: "application/json"
      )

      response.status.should eq 422

      queue.reload
      queue.total_price.should eq "33000.0"
    end

    it "returns 404 when queue does not exist" do
      response = Marten::Spec.client.patch(
        Marten.routes.reverse("antrikan:queue:update", queue_slug: "UNKNOWN00"),
        data: {note: "x"}.to_json,
        content_type: "application/json"
      )

      response.status.should eq 404
    end

    it "returns 422 when handler organization does not match queue organization" do
      organization = create_organization
      owner = create_user(organization: organization)
      space = create_space(manager: owner)
      channel = create_channel(space: space)
      queue = create_queue(channel: channel, queuer: create_queuer(space: space))

      outsider = create_user(organization: create_organization)

      response = Marten::Spec.client.patch(
        Marten.routes.reverse("antrikan:queue:update", queue_slug: queue.slug!),
        data: {
          handler_id: outsider.hashed_id,
        }.to_json,
        content_type: "application/json"
      )

      response.status.should eq 422

      queue.reload
      queue.handler_id.should be_nil
    end

    it "returns 404 when handler_id does not exist" do
      queue = create_queue

      response = Marten::Spec.client.patch(
        Marten.routes.reverse("antrikan:queue:update", queue_slug: queue.slug!),
        data: {
          handler_id: IdConcealer.encode(9_999_999),
        }.to_json,
        content_type: "application/json"
      )

      response.status.should eq 404

      queue.reload
      queue.handler_id.should be_nil
    end

    it "forbids regressing status from READY to QUEUED" do
      queue = create_queue(status: Antrikan::QueueStatus::READY)

      response = Marten::Spec.client.patch(
        Marten.routes.reverse("antrikan:queue:update", queue_slug: queue.slug!),
        data: {
          status: Antrikan::QueueStatus::QUEUED,
        }.to_json,
        content_type: "application/json"
      )

      response.status.should eq 422

      queue.reload
      queue.status.should eq Antrikan::QueueStatus::READY.value
    end

    it "forbids regressing status from DONE to DISPATCHING" do
      queue = create_queue(status: Antrikan::QueueStatus::DONE)

      response = Marten::Spec.client.patch(
        Marten.routes.reverse("antrikan:queue:update", queue_slug: queue.slug!),
        data: {
          status: Antrikan::QueueStatus::DISPATCHING,
        }.to_json,
        content_type: "application/json"
      )

      response.status.should eq 422

      queue.reload
      queue.status.should eq Antrikan::QueueStatus::DONE.value
    end

    it "returns 422 for unknown status event" do
      queue = create_queue(status: Antrikan::QueueStatus::QUEUED)

      response = Marten::Spec.client.patch(
        Marten.routes.reverse("antrikan:queue:update", queue_slug: queue.slug!),
        data: {
          status: "noop",
        }.to_json,
        content_type: "application/json"
      )

      response.status.should eq 422

      queue.reload
      queue.status.should eq Antrikan::QueueStatus::QUEUED.value
    end
  end
end
