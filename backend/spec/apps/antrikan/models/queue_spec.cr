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
    it "allows a handler from the same organization as the channel space owner" do
      organization = create_organization
      owner = create_user(organization: organization)
      space = create_space(owner: owner)
      queue = create_queue(
        channel: create_channel(space: space),
        queuer: create_queuer(space: space),
        handler: create_user(organization: organization)
      )

      queue.valid?.should be_true
    end

    it "rejects a handler from a different organization than the channel space owner" do
      owner = create_user(organization: create_organization)
      space = create_space(owner: owner)
      queue = Antrikan::Queue.new
      queue.queuer = create_queuer(space: space)
      queue.channel = create_channel(space: space)
      queue.handler = create_user

      queue.valid?.should be_false
      queue.errors[:handler][0].message.should eq "must be from the same organization as the channel space owner"
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
end
