require "./spec_helper"

describe Antrikan::QueuedItem::CreatorService do
  describe "#run" do
    context "with valid item_slug" do
      it "creates a queued item and publishes event" do
        queue = create_queue
        item = create_item(channel: queue.channel!)
        cid = queue.channel!

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
        item = create_item(channel: queue.channel!)

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
  end
end
