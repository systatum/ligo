require "../spec_helper"

describe Antrikan::QueuedItem do
  describe "lifecycle fields" do
    it "sets attended_at when status becomes attended" do
      queued_item = create_queued_item
      queued_item.attended_at.should be_nil

      queued_item.change_status!(:attended)
      queued_item.save!

      queued_item.reload
      queued_item.attended_at.should_not be_nil
    end

    it "sets packed_at when status becomes packed" do
      queued_item = create_queued_item
      queued_item.packed_at.should be_nil

      queued_item.change_status!(:packed)
      queued_item.save!

      queued_item.reload
      queued_item.packed_at.should_not be_nil
    end

    it "sets ready_at when status becomes ready" do
      queued_item = create_queued_item
      queued_item.ready_at.should be_nil

      queued_item.change_status!(:ready)
      queued_item.save!

      queued_item.reload
      queued_item.ready_at.should_not be_nil
    end

    it "sets dispatched_at when status becomes dispatching" do
      queued_item = create_queued_item
      queued_item.dispatched_at.should be_nil

      queued_item.change_status!(:dispatching)
      queued_item.save!

      queued_item.reload
      queued_item.dispatched_at.should_not be_nil
    end

    it "sets delivered_at when status becomes done" do
      queued_item = create_queued_item
      queued_item.delivered_at.should be_nil

      queued_item.change_status!(:done)
      queued_item.save!

      queued_item.reload
      queued_item.delivered_at.should_not be_nil
    end

    it "soft-deletes when status becomes canceled" do
      queued_item = create_queued_item
      queued_item.deleted_at.should be_nil

      queued_item.change_status!(:canceled)
      queued_item.save!

      deleted_item = Antrikan::QueuedItem.unscoped.get!(id: queued_item.id!)
      deleted_item.deleted_at.should_not be_nil
    end
  end

  describe "parent queue synchronization" do
    it "moves parent queue to attended when any item is not done" do
      queue = create_queue(status: Antrikan::QueueStatus::QUEUED)

      create_queued_item(
        queue: queue,
        status: Antrikan::QueueStatus::DONE,
        unit_price: 20_000_i64,
        quantity: 1
      )
      create_queued_item(
        queue: queue,
        status: Antrikan::QueueStatus::QUEUED,
        unit_price: 15_000_i64,
        quantity: 2
      )

      queue.reload
      queue.status.should eq Antrikan::QueueStatus::ATTENDED.value
      queue.total_price.should eq 50_000_i64
    end

    it "moves parent queue to ready when all active items are done" do
      queue = create_queue(status: Antrikan::QueueStatus::QUEUED)

      create_queued_item(
        queue: queue,
        status: Antrikan::QueueStatus::DONE,
        unit_price: 10_000_i64,
        quantity: 1
      )
      create_queued_item(
        queue: queue,
        status: Antrikan::QueueStatus::DONE,
        unit_price: 5_000_i64,
        quantity: 3
      )

      queue.reload
      queue.status.should eq Antrikan::QueueStatus::READY.value
      queue.total_price.should eq 25_000_i64
      queue.ready_at.should_not be_nil
    end

    it "moves parent queue to ready when one item is canceled and the other is done" do
      queue = create_queue(status: Antrikan::QueueStatus::QUEUED)

      create_queued_item(
        queue: queue,
        status: Antrikan::QueueStatus::DONE,
        unit_price: 10_000_i64,
        quantity: 1
      )
      canceled_item = create_queued_item(
        queue: queue,
        status: Antrikan::QueueStatus::QUEUED,
        unit_price: 7_500_i64,
        quantity: 2
      )

      canceled_item.change_status!(:canceled)
      canceled_item.save!

      queue.reload
      queue.status.should eq Antrikan::QueueStatus::READY.value
      queue.total_price.should eq 10_000_i64
      queue.ready_at.should_not be_nil
    end

    it "recomputes parent queue total_price when items are canceled" do
      queue = create_queue(status: Antrikan::QueueStatus::QUEUED)

      item_a = create_queued_item(
        queue: queue,
        status: Antrikan::QueueStatus::QUEUED,
        unit_price: 12_000_i64,
        quantity: 1
      )
      create_queued_item(
        queue: queue,
        status: Antrikan::QueueStatus::QUEUED,
        unit_price: 8_000_i64,
        quantity: 2
      )

      queue.reload
      queue.total_price.should eq 28_000_i64

      item_a.change_status!(:canceled)
      item_a.save!

      queue.reload
      queue.total_price.should eq 16_000_i64
    end
  end

  describe "state machine" do
    it "starts from queued after initialization" do
      queued_item = create_queued_item

      queued_item.state.should eq :queued
      queued_item.next_state.should eq :attended
    end

    it "transitions to done through normal progression" do
      queued_item = create_queued_item

      queued_item.fire!(:attended)
      queued_item.state.should eq :attended

      queued_item.fire!(:packed)
      queued_item.state.should eq :packed

      queued_item.fire!(:ready)
      queued_item.state.should eq :ready

      queued_item.fire!(:dispatching)
      queued_item.state.should eq :dispatching

      queued_item.fire!(:done)
      queued_item.state.should eq :done
    end

    it "supports cancellation" do
      queued_item = create_queued_item

      queued_item.fire!(:canceled)
      queued_item.state.should eq :canceled
    end

    it "raises on invalid transition when using fire!" do
      queued_item = create_queued_item(status: Antrikan::QueueStatus::DONE)

      expect_raises(AASM::UnableToChangeState) do
        queued_item.fire!(:ready)
      end
    end
  end
end
