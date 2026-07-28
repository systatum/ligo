require "./spec_helper"

describe Antrikan::QueueCreateHandler do
  context "when the request payload is valid" do
    it "creates a queue with required fields only" do
      space = create_space
      queuer = create_queuer(space: space)

      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:space:queue:create", space_hashed_id: space.hashed_id),
        data: {
          queuer_id: queuer.hashed_id,
        }.to_json,
        content_type: "application/json"
      )

      response.status.should eq 201

      queue = Antrikan::Queue.last!
      queue.id.should_not be_nil
      queue.space_id.should eq space.id
      queue.queuer_id.should eq queuer.id
      queue.status.should eq Antrikan::QueueStatus::QUEUED.value
      queue.payment_status.should eq Antrikan::PaymentStatus::UNPAID.value
      queue.total_price.should eq "0.0"

      response.content.should eq Antrikan::QueueSerializer.serialize(queue)
    end

    it "accepts optional fields" do
      space = create_space
      queuer = create_queuer(space: space)
      user = create_user(organization: space.manager.not_nil!.organization.not_nil!)

      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:space:queue:create", space_hashed_id: space.hashed_id),
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
      queue.space_id.should eq space.id
      queue.handler_id.should eq user.id
      queue.note.should eq "we accept optional fields"
      queue.status.should eq Antrikan::QueueStatus::QUEUED.value
      queue.payment_status.should eq Antrikan::PaymentStatus::PARTIAL.value
      queue.fully_paid_at.not_nil!.to_rfc3339.should eq "2026-05-23T10:15:00Z"

      response.content.should eq Antrikan::QueueSerializer.serialize(queue)
    end

    it "allows creating with non-queued status (state jump)" do
      space = create_space
      queuer = create_queuer(space: space)

      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:space:queue:create", space_hashed_id: space.hashed_id),
        data: {
          queuer_id: queuer.hashed_id,
          status:    Antrikan::QueueStatus::DONE,
        }.to_json,
        content_type: "application/json"
      )

      response.status.should eq 201

      queue = Antrikan::Queue.last!
      queue.space_id.should eq space.id
      queue.queuer_id.should eq queuer.id
      queue.status.should eq Antrikan::QueueStatus::DONE.value

      response.content.should eq Antrikan::QueueSerializer.serialize(queue)
    end

    it "soft-deletes queue when creating with CANCELED status" do
      space = create_space
      queuer = create_queuer(space: space)

      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:space:queue:create", space_hashed_id: space.hashed_id),
        data: {
          queuer_id: queuer.hashed_id,
          status:    Antrikan::QueueStatus::CANCELED,
        }.to_json,
        content_type: "application/json"
      )

      response.status.should eq 201

      queue = Antrikan::Queue.unscoped.last!
      queue.space_id.should eq space.id
      queue.queuer_id.should eq queuer.id
      queue.status.should eq Antrikan::QueueStatus::CANCELED.value
      queue.deleted_at.should_not be_nil

      response.content.should eq Antrikan::QueueSerializer.serialize(queue)
    end

    it "creates queued items from a bulk items array" do
      space = create_space
      channel = create_channel(space: space)
      queuer = create_queuer(space: space)
      item_a = create_item(channel: channel)
      item_b = create_item(channel: channel)

      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:space:queue:create", space_hashed_id: space.hashed_id),
        data: {
          queuer_id: queuer.hashed_id,
          items:     [
            {item_slug: item_a.slug, quantity: 2},
            {item_slug: item_b.slug},
          ],
        }.to_json,
        content_type: "application/json"
      )

      response.status.should eq 201

      queue = Antrikan::Queue.last!
      queued_items = Antrikan::QueuedItem.filter(queue_id: queue.id!).to_a
      queued_items.size.should eq 2
      queued_items.map(&.item_id).to_set.should eq Set{item_a.id!, item_b.id!}
    end

    it "creates queued items from a bulk items array spanning multiple channels" do
      space = create_space
      channel_a = create_channel(space: space)
      channel_b = create_channel(space: space)
      queuer = create_queuer(space: space)
      item_a = create_item(channel: channel_a)
      item_b = create_item(channel: channel_b)

      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:space:queue:create", space_hashed_id: space.hashed_id),
        data: {
          queuer_id: queuer.hashed_id,
          items:     [
            {item_slug: item_a.slug},
            {item_slug: item_b.slug},
          ],
        }.to_json,
        content_type: "application/json"
      )

      response.status.should eq 201

      queue = Antrikan::Queue.last!
      queued_items = Antrikan::QueuedItem.filter(queue_id: queue.id!).to_a
      queued_items.map(&.channel_id).to_set.should eq Set{channel_a.id!, channel_b.id!}
    end

    it "attaches a voucher via voucher_code" do
      space = create_space
      queuer = create_queuer(space: space)
      voucher = create_voucher(space: space, code: "SAVE10", space_percentage_discount: 10.0)

      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:space:queue:create", space_hashed_id: space.hashed_id),
        data: {
          queuer_id:    queuer.hashed_id,
          voucher_code: voucher.code,
        }.to_json,
        content_type: "application/json"
      )

      response.status.should eq 201

      queue = Antrikan::Queue.last!
      applied = Antrikan::AppliedVoucher.filter(queue_id: queue.id!).to_a
      applied.size.should eq 1
      applied[0].voucher_id.should eq voucher.id
    end

    it "attaches a non-anonymously-redeemable voucher when the queuer is a registered user" do
      space = create_space
      user = create_user(organization: space.manager.not_nil!.organization.not_nil!)
      queuer = create_queuer(space: space, user: user)
      voucher = create_voucher(
        space: space,
        code: "MEMBERS10",
        space_percentage_discount: 10.0,
        anon_redeemable: false
      )

      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:space:queue:create", space_hashed_id: space.hashed_id),
        data: {
          queuer_id:    queuer.hashed_id,
          voucher_code: voucher.code,
        }.to_json,
        content_type: "application/json"
      )

      response.status.should eq 201

      queue = Antrikan::Queue.last!
      applied = Antrikan::AppliedVoucher.filter(queue_id: queue.id!).first!
      applied.redeemer_id.should eq user.id
    end

    it "does not record a redeemer for an anonymously-redeemable voucher" do
      space = create_space
      queuer = create_queuer(space: space)
      voucher = create_voucher(space: space, code: "SAVE10", space_percentage_discount: 10.0)

      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:space:queue:create", space_hashed_id: space.hashed_id),
        data: {
          queuer_id:    queuer.hashed_id,
          voucher_code: voucher.code,
        }.to_json,
        content_type: "application/json"
      )

      response.status.should eq 201

      queue = Antrikan::Queue.last!
      applied = Antrikan::AppliedVoucher.filter(queue_id: queue.id!).first!
      applied.redeemer_id.should be_nil
    end

    it "allows a second redemption by the same user when under max_redeem_per_user" do
      space = create_space
      user = create_user(organization: space.manager.not_nil!.organization.not_nil!)
      voucher = create_voucher(
        space: space,
        code: "LIMIT2",
        space_percentage_discount: 10.0,
        anon_redeemable: false,
        max_redeem_per_user: 2
      )

      2.times do
        queuer = create_queuer(space: space, user: user)

        response = Marten::Spec.client.post(
          Marten.routes.reverse("antrikan:space:queue:create", space_hashed_id: space.hashed_id),
          data: {
            queuer_id:    queuer.hashed_id,
            voucher_code: voucher.code,
          }.to_json,
          content_type: "application/json"
        )

        response.status.should eq 201
      end

      Antrikan::AppliedVoucher.filter(voucher_id: voucher.id!, redeemer_id: user.id!).count.should eq 2
    end
  end

  context "when the request payload is invalid" do
    it "does not create anything when one bulk item entry is invalid" do
      space = create_space
      channel = create_channel(space: space)
      queuer = create_queuer(space: space)
      valid_item = create_item(channel: channel)
      other_space_item = create_item(channel: create_channel)

      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:space:queue:create", space_hashed_id: space.hashed_id),
        data: {
          queuer_id: queuer.hashed_id,
          items:     [
            {item_slug: valid_item.slug},
            {item_slug: other_space_item.slug},
          ],
        }.to_json,
        content_type: "application/json"
      )

      response.status.should eq 422
      Antrikan::Queue.filter(queuer_id: queuer.id!).exists?.should be_false
      Antrikan::QueuedItem.filter(item_id: valid_item.id!).exists?.should be_false
    end

    it "returns 422 for an invalid voucher_code" do
      space = create_space
      queuer = create_queuer(space: space)

      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:space:queue:create", space_hashed_id: space.hashed_id),
        data: {
          queuer_id:    queuer.hashed_id,
          voucher_code: "NOT-A-CODE",
        }.to_json,
        content_type: "application/json"
      )

      response.status.should eq 422
      response.content.should contain Antrikan::ErrorCode::VOUCHER_NOT_FOUND
      Antrikan::Queue.filter(queuer_id: queuer.id!).exists?.should be_false
    end

    it "returns 422 for a non-anonymously-redeemable voucher when the queuer has no registered user" do
      space = create_space
      queuer = create_queuer(space: space)
      voucher = create_voucher(
        space: space,
        code: "MEMBERS10",
        space_percentage_discount: 10.0,
        anon_redeemable: false
      )

      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:space:queue:create", space_hashed_id: space.hashed_id),
        data: {
          queuer_id:    queuer.hashed_id,
          voucher_code: voucher.code,
        }.to_json,
        content_type: "application/json"
      )

      response.status.should eq 422
      response.content.should contain Antrikan::ErrorCode::VOUCHER_NOT_ANON_REDEEMABLE
      Antrikan::Queue.filter(queuer_id: queuer.id!).exists?.should be_false
    end

    it "returns 422 once the same user reaches max_redeem_per_user" do
      space = create_space
      user = create_user(organization: space.manager.not_nil!.organization.not_nil!)
      voucher = create_voucher(
        space: space,
        code: "LIMIT1",
        space_percentage_discount: 10.0,
        anon_redeemable: false,
        max_redeem_per_user: 1
      )

      first_queuer = create_queuer(space: space, user: user)
      first = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:space:queue:create", space_hashed_id: space.hashed_id),
        data: {
          queuer_id:    first_queuer.hashed_id,
          voucher_code: voucher.code,
        }.to_json,
        content_type: "application/json"
      )
      first.status.should eq 201

      second_queuer = create_queuer(space: space, user: user)
      second = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:space:queue:create", space_hashed_id: space.hashed_id),
        data: {
          queuer_id:    second_queuer.hashed_id,
          voucher_code: voucher.code,
        }.to_json,
        content_type: "application/json"
      )

      second.status.should eq 422
      second.content.should contain Antrikan::ErrorCode::VOUCHER_REDEEMER_MAXED_QUOTA
      Antrikan::AppliedVoucher.filter(voucher_id: voucher.id!, redeemer_id: user.id!).count.should eq 1
    end

    it "returns 422 for a voucher outside its active window" do
      space = create_space
      queuer = create_queuer(space: space)
      voucher = create_voucher(
        space: space,
        code: "EXPIRED",
        space_percentage_discount: 10.0,
        indeterminate: false,
        starts_at: Time.utc(2020, 1, 1),
        expires_at: Time.utc(2020, 12, 31)
      )

      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:space:queue:create", space_hashed_id: space.hashed_id),
        data: {
          queuer_id:    queuer.hashed_id,
          voucher_code: voucher.code,
        }.to_json,
        content_type: "application/json"
      )

      response.status.should eq 422
      response.content.should contain Antrikan::ErrorCode::VOUCHER_INACTIVE
      Antrikan::Queue.filter(queuer_id: queuer.id!).exists?.should be_false
    end

    it "returns 422 when queuer_id is missing" do
      space = create_space

      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:space:queue:create", space_hashed_id: space.hashed_id),
        data: {
          note: "no queuer",
        }.to_json,
        content_type: "application/json"
      )

      response.status.should eq 422
    end

    it "returns 404 when space does not exist" do
      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:space:queue:create", space_hashed_id: IdConcealer.encode(9_999_999)),
        data: {
          queuer_id: IdConcealer.encode(1),
        }.to_json,
        content_type: "application/json"
      )

      response.status.should eq 404
    end

    it "returns 422 when handler's organization does not match space owner's" do
      space = create_space
      queuer = create_queuer(space: space)

      other_org = create_organization
      other_user = create_user(organization: other_org)

      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:space:queue:create", space_hashed_id: space.hashed_id),
        data: {
          queuer_id:  queuer.hashed_id,
          handler_id: other_user.hashed_id,
        }.to_json,
        content_type: "application/json"
      )

      response.status.should eq 422
    end

    it "throttles repeated create attempts by ip and queuer_id" do
      space = create_space
      queuer = create_queuer(space: space)
      path = Marten.routes.reverse("antrikan:space:queue:create", space_hashed_id: space.hashed_id)

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
      space = create_space
      queuer_a = create_queuer(space: space)
      queuer_b = create_queuer(space: space)
      path = Marten.routes.reverse("antrikan:space:queue:create", space_hashed_id: space.hashed_id)

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
