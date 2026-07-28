require "../spec_helper"

describe "Antrikan::Queue" do
  describe "slug generation" do
    it "generates 8-char slug with 2-digit current year prefix" do
      queue = create_queue
      year_prefix = "%02d" % (Time.utc.year % 100)

      queue.slug.not_nil!.size.should eq 8
      queue.slug.not_nil!.starts_with?(year_prefix).should be_true
    end
  end

  describe "validations" do
    it "allows a handler from the same organization as the space owner" do
      organization = create_organization
      owner = create_user(organization: organization)
      space = create_space(manager: owner)
      queue = create_queue(
        space: space,
        queuer: create_queuer(space: space),
        handler: create_user(organization: organization)
      )

      queue.valid?.should be_true
    end

    it "rejects a handler from a different organization than the space owner" do
      owner = create_user(organization: create_organization)
      space = create_space(manager: owner)
      queue = Antrikan::Queue.new
      queue.queuer = create_queuer(space: space)
      queue.space = space
      queue.handler = create_user

      queue.valid?.should be_false
      queue.errors[:handler][0].message.should eq "must be from the same organization as the space owner"
    end
  end

  describe "balance accessors" do
    it "aggregates amount_paid, amount_refunded and paid_balance across payments" do
      queue = create_queue
      first_payment = create_payment(queue: queue, amount: BigFloat.new(100))
      second_payment = create_payment(queue: queue, amount: BigFloat.new(50))
      create_refund(payment: first_payment, amount: BigFloat.new(20), status: Antrikan::RefundStatus::ACCEPTED)
      create_refund(payment: second_payment, amount: BigFloat.new(10), status: Antrikan::RefundStatus::PENDING)

      queue.amount_paid.should eq BigFloat.new(150)
      queue.amount_refunded.should eq BigFloat.new(20)
      queue.paid_balance.should eq BigFloat.new(130)
    end

    it "ignores soft-deleted payments" do
      queue = create_queue
      payment = create_payment(queue: queue, amount: BigFloat.new(100))
      payment.deleted_at = Time.utc
      payment.save!

      queue.amount_paid.should eq BigFloat.new(0)
      queue.paid_balance.should eq BigFloat.new(0)
    end

    it "is zero when there are no payments" do
      queue = create_queue

      queue.amount_paid.should eq BigFloat.new(0)
      queue.amount_refunded.should eq BigFloat.new(0)
      queue.paid_balance.should eq BigFloat.new(0)
    end
  end

  describe "lifecycle fields" do
    it "sets attended_at when status becomes attended" do
      queue = create_queue
      queue.attended_at.should be_nil

      queue.change_status!(:attended)
      queue.save!

      queue.reload
      queue.attended_at.should_not be_nil
    end

    it "sets packed_at when status becomes packed" do
      queue = create_queue
      queue.packed_at.should be_nil

      queue.change_status!(:packed)
      queue.save!

      queue.reload
      queue.packed_at.should_not be_nil
    end

    it "sets ready_at when status becomes ready" do
      queue = create_queue
      queue.ready_at.should be_nil

      queue.change_status!(:ready)
      queue.save!

      queue.reload
      queue.ready_at.should_not be_nil
    end

    it "sets dispatched_at when status becomes dispatching" do
      queue = create_queue
      queue.dispatched_at.should be_nil

      queue.change_status!(:dispatching)
      queue.save!

      queue.reload
      queue.dispatched_at.should_not be_nil
    end

    it "sets delivered_at when status becomes done" do
      queue = create_queue
      queue.delivered_at.should be_nil

      queue.change_status!(:done)
      queue.save!

      queue.reload
      queue.delivered_at.should_not be_nil
    end

    it "soft-deletes when status becomes canceled" do
      queue = create_queue
      queue.deleted_at.should be_nil

      queue.change_status!(:canceled)
      queue.save!

      deleted_queue = Antrikan::Queue.unscoped.get!(id: queue.id!)
      deleted_queue.deleted_at.should_not be_nil
    end
  end

  describe "state machine" do
    it "starts from queued after initialization" do
      queue = create_queue

      queue.state.should eq :queued
      queue.next_state.should eq :attended
    end

    it "transitions to done through normal progression" do
      queue = create_queue

      queue.fire!(:attended)
      queue.state.should eq :attended

      queue.fire!(:packed)
      queue.state.should eq :packed

      queue.fire!(:ready)
      queue.state.should eq :ready

      queue.fire!(:dispatching)
      queue.state.should eq :dispatching

      queue.fire!(:done)
      queue.state.should eq :done
    end

    it "allows cancellation from queued" do
      queue = create_queue

      queue.fire!(:canceled)
      queue.state.should eq :canceled
    end

    it "raises on invalid transition when using fire!" do
      queue = create_queue(status: Antrikan::QueueStatus::DONE)

      expect_raises(AASM::UnableToChangeState) do
        queue.fire!(:ready)
      end
    end
  end

  describe "when publishing events to redis" do
    it "publishes queue_updated event when status changes during sync" do
      queue = create_queue
      cid = create_channel(space: queue.space!)

      msg = capture_redis_message("socky:channel:antrikan:#{cid.hashed_id}") do
        create_queued_item(
          queue: queue,
          item: create_item(channel: cid),
          status: Antrikan::QueueStatus::DONE,
        )
      end

      queue.reload
      queue.status.should eq Antrikan::QueueStatus::READY.value

      msg.should_not be_nil
      json = JSON.parse(msg.not_nil!)
      json["type"].as_s.should eq "queue_updated"
    end

    it "fans out to every channel represented among the queue's items, not just one" do
      queue = create_queue
      channel_a = create_channel(space: queue.space!)
      channel_b = create_channel(space: queue.space!)

      create_queued_item(queue: queue, channel: channel_a, status: Antrikan::QueueStatus::DONE)

      messages = capture_redis_messages_by_channel(
        ["socky:channel:antrikan:#{channel_a.hashed_id}", "socky:channel:antrikan:#{channel_b.hashed_id}"],
      ) do
        create_queued_item(queue: queue, channel: channel_b, status: Antrikan::QueueStatus::QUEUED)
      end

      queue.reload
      queue.status.should eq Antrikan::QueueStatus::ATTENDED.value

      messages.keys.to_set.should eq Set{
        "socky:channel:antrikan:#{channel_a.hashed_id}",
        "socky:channel:antrikan:#{channel_b.hashed_id}",
      }
      messages.each_value do |payloads|
        payloads.each do |payload|
          JSON.parse(payload)["type"].as_s.should eq "queue_updated"
        end
      end
    end
  end
end
