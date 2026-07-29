require "./spec_helper"

describe Antrikan::QueuedItem::CreatorService do
  describe "#run" do
    context "with valid item_slug" do
      it "creates a queued item and publishes event" do
        queue = create_queue
        cid = create_channel(space: queue.space!)
        item = create_item(channel: cid)

        raw_hash = Marten::HTTP::Params::Data::RawHash.new
        raw_hash["item_slug"] = [item.slug!]

        msg = capture_redis_message("socky:channel:antrikan:#{cid.hashed_id}") do
          result = Antrikan::QueuedItem::CreatorService.new(
            queue,
            Marten::HTTP::Params::Data.new(raw_hash),
          ).run

          result.success?.should be_true
        end

        msg.should_not be_nil
        json = JSON.parse(msg.not_nil!)
        {"queued_item_created", "queue_updated"}.should contain(json["type"].as_s)
      end

      it "creates item with note and quantity" do
        queue = create_queue
        item = create_item(channel: create_channel(space: queue.space!))

        raw_hash = Marten::HTTP::Params::Data::RawHash.new
        raw_hash["item_slug"] = [item.slug!]
        raw_hash["note"] = ["extra cheese"]
        raw_hash["quantity"] = [JSON.parse("2")]

        result = Antrikan::QueuedItem::CreatorService.new(
          queue,
          Marten::HTTP::Params::Data.new(raw_hash),
        ).run

        result.success?.should be_true
        result.data.not_nil!.note.should eq "extra cheese"
        result.data.not_nil!.quantity.should eq 2
      end
    end

    context "with missing required fields" do
      it "returns failure when item_slug is missing" do
        queue = create_queue
        raw_hash = Marten::HTTP::Params::Data::RawHash.new

        result = Antrikan::QueuedItem::CreatorService.new(
          queue,
          Marten::HTTP::Params::Data.new(raw_hash),
        ).run

        result.success?.should be_false
      end
    end

    context "with invalid item_slug" do
      it "raises RecordNotFound" do
        queue = create_queue
        raw_hash = Marten::HTTP::Params::Data::RawHash.new
        raw_hash["item_slug"] = ["nonexistent"]

        expect_raises(Marten::DB::Errors::RecordNotFound) do
          Antrikan::QueuedItem::CreatorService.new(
            queue,
            Marten::HTTP::Params::Data.new(raw_hash),
          ).run
        end
      end
    end

    context "when the channel enforces operating hours" do
      it "rejects an item outside its operating hours" do
        # Pick whichever half of the day excludes the current hour, so this doesn't
        # flake depending on what time the test happens to run.
        now = Time.utc
        open_hour, close_hour = now.hour < 12 ? {12, 23} : {0, 11}

        channel = create_channel(enforce_operating_hours: true)
        queue = create_queue(space: channel.space!)
        item = create_item(channel: channel)
        create_operating_hour(
          item: item,
          day: now.day_of_week.value - 1,
          open_time: Time::Span.new(hours: open_hour, minutes: 0),
          close_time: Time::Span.new(hours: close_hour, minutes: 0)
        )

        raw_hash = Marten::HTTP::Params::Data::RawHash.new
        raw_hash["item_slug"] = [item.slug!]

        result = Antrikan::QueuedItem::CreatorService.new(
          queue,
          Marten::HTTP::Params::Data.new(raw_hash),
        ).run

        result.success?.should be_false
      end

      it "allows an item within its operating hours" do
        channel = create_channel(enforce_operating_hours: true)
        queue = create_queue(space: channel.space!)
        item = create_item(channel: channel)
        create_operating_hour(
          item: item,
          day: Time.utc.day_of_week.value - 1,
          open_time: Time::Span.new(hours: 0, minutes: 0),
          close_time: Time::Span.new(hours: 23, minutes: 59, seconds: 59)
        )

        raw_hash = Marten::HTTP::Params::Data::RawHash.new
        raw_hash["item_slug"] = [item.slug!]

        result = Antrikan::QueuedItem::CreatorService.new(
          queue,
          Marten::HTTP::Params::Data.new(raw_hash),
        ).run

        result.success?.should be_true
      end

      it "allows an item with no configured operating hours" do
        channel = create_channel(enforce_operating_hours: true)
        queue = create_queue(space: channel.space!)
        item = create_item(channel: channel)

        raw_hash = Marten::HTTP::Params::Data::RawHash.new
        raw_hash["item_slug"] = [item.slug!]

        result = Antrikan::QueuedItem::CreatorService.new(
          queue,
          Marten::HTTP::Params::Data.new(raw_hash),
        ).run

        result.success?.should be_true
      end
    end

    context "when the channel does not enforce operating hours" do
      it "allows an item outside its operating hours" do
        channel = create_channel(enforce_operating_hours: false)
        queue = create_queue(space: channel.space!)
        item = create_item(channel: channel)
        create_operating_hour(
          item: item,
          day: Time.utc.day_of_week.value - 1,
          open_time: Time::Span.new(hours: 0, minutes: 0),
          close_time: Time::Span.new(hours: 1, minutes: 0)
        )

        raw_hash = Marten::HTTP::Params::Data::RawHash.new
        raw_hash["item_slug"] = [item.slug!]

        result = Antrikan::QueuedItem::CreatorService.new(
          queue,
          Marten::HTTP::Params::Data.new(raw_hash),
        ).run

        result.success?.should be_true
      end
    end

    context "when the channel limits items per queue via max_item_piece" do
      it "rejects adding an item once the limit is already met" do
        channel = create_channel(max_item_piece: 1)
        queue = create_queue(space: channel.space!)
        item = create_item(channel: channel)
        create_queued_item(queue: queue, item: item, channel: channel)

        raw_hash = Marten::HTTP::Params::Data::RawHash.new
        raw_hash["item_slug"] = [item.slug!]

        result = Antrikan::QueuedItem::CreatorService.new(
          queue,
          Marten::HTTP::Params::Data.new(raw_hash),
        ).run

        result.success?.should be_false
      end

      it "allows adding an item while still under the limit" do
        channel = create_channel(max_item_piece: 2)
        queue = create_queue(space: channel.space!)
        item = create_item(channel: channel)
        create_queued_item(queue: queue, item: item, channel: channel)

        raw_hash = Marten::HTTP::Params::Data::RawHash.new
        raw_hash["item_slug"] = [item.slug!]

        result = Antrikan::QueuedItem::CreatorService.new(
          queue,
          Marten::HTTP::Params::Data.new(raw_hash),
        ).run

        result.success?.should be_true
      end

      it "does not count a canceled item of the same channel toward the limit" do
        channel = create_channel(max_item_piece: 1)
        queue = create_queue(space: channel.space!)
        item = create_item(channel: channel)
        existing = create_queued_item(queue: queue, item: item, channel: channel)
        existing.change_status!(:canceled)
        existing.save!

        raw_hash = Marten::HTTP::Params::Data::RawHash.new
        raw_hash["item_slug"] = [item.slug!]

        result = Antrikan::QueuedItem::CreatorService.new(
          queue,
          Marten::HTTP::Params::Data.new(raw_hash),
        ).run

        result.success?.should be_true
      end

      it "allows unlimited items when max_item_piece is -1" do
        channel = create_channel(max_item_piece: -1)
        queue = create_queue(space: channel.space!)
        item = create_item(channel: channel)
        create_queued_item(queue: queue, item: item, channel: channel)
        create_queued_item(queue: queue, item: item, channel: channel)

        raw_hash = Marten::HTTP::Params::Data::RawHash.new
        raw_hash["item_slug"] = [item.slug!]

        result = Antrikan::QueuedItem::CreatorService.new(
          queue,
          Marten::HTTP::Params::Data.new(raw_hash),
        ).run

        result.success?.should be_true
      end

      it "counts every item in the channel toward the same limit, not just matching slugs" do
        channel = create_channel(max_item_piece: 1)
        queue = create_queue(space: channel.space!)
        first_item = create_item(channel: channel)
        create_queued_item(queue: queue, item: first_item, channel: channel)

        second_item = create_item(channel: channel)
        raw_hash = Marten::HTTP::Params::Data::RawHash.new
        raw_hash["item_slug"] = [second_item.slug!]

        result = Antrikan::QueuedItem::CreatorService.new(
          queue,
          Marten::HTTP::Params::Data.new(raw_hash),
        ).run

        result.success?.should be_false
      end
    end
  end
end
