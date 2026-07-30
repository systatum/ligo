require "./spec_helper"

describe Antrikan::Queue::EstimatorService do
  describe "#run" do
    it "counts other active items ahead of the queue in a single channel" do
      channel = create_channel
      ahead_a = create_queue(space: channel.space!)
      create_queued_item(queue: ahead_a, channel: channel)
      ahead_b = create_queue(space: channel.space!)
      create_queued_item(queue: ahead_b, channel: channel)

      queue = create_queue(space: channel.space!)
      create_queued_item(queue: queue, channel: channel)

      result = Antrikan::Queue::EstimatorService.new(queue).run

      result.success?.should be_true
      estimations = result.data.not_nil!
      estimations.size.should eq 1
      estimations[0].channel.id.should eq channel.id
      estimations[0].items_ahead.should eq 2
    end

    it "reports estimation for every channel the queue has active items in" do
      space = create_space
      channel_a = create_channel(space: space)
      channel_b = create_channel(space: space)
      queue = create_queue(space: space)
      create_queued_item(queue: queue, channel: channel_a)
      create_queued_item(queue: queue, channel: channel_b)

      result = Antrikan::Queue::EstimatorService.new(queue).run

      channel_ids = result.data.not_nil!.map(&.channel.id).to_set
      channel_ids.should eq Set{channel_a.id, channel_b.id}
    end

    it "excludes a channel once all of the queue's items in it are done" do
      channel = create_channel
      queue = create_queue(space: channel.space!)
      create_queued_item(queue: queue, channel: channel, status: Antrikan::QueueStatus::DONE)

      result = Antrikan::Queue::EstimatorService.new(queue).run

      result.data.not_nil!.should be_empty
    end

    it "does not count items from other queues that arrived after this queue's item" do
      channel = create_channel
      queue = create_queue(space: channel.space!)
      create_queued_item(queue: queue, channel: channel)

      later_queue = create_queue(space: channel.space!)
      create_queued_item(queue: later_queue, channel: channel)

      result = Antrikan::Queue::EstimatorService.new(queue).run

      result.data.not_nil![0].items_ahead.should eq 0
    end

    it "does not count another queue's already-done item as ahead" do
      channel = create_channel
      done_queue = create_queue(space: channel.space!)
      create_queued_item(queue: done_queue, channel: channel, status: Antrikan::QueueStatus::DONE)

      queue = create_queue(space: channel.space!)
      create_queued_item(queue: queue, channel: channel)

      result = Antrikan::Queue::EstimatorService.new(queue).run

      result.data.not_nil![0].items_ahead.should eq 0
    end

    it "returns no estimations when the queue has no items at all" do
      queue = create_queue

      result = Antrikan::Queue::EstimatorService.new(queue).run

      result.data.not_nil!.should be_empty
    end
  end
end
