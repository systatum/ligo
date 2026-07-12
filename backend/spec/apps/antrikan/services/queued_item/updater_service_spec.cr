require "./spec_helper"

describe Antrikan::QueuedItem::UpdaterService do
  describe "#run" do
    context "with valid update" do
      it "updates note and publishes event" do
        qi = create_queued_item(note: "old note")
        cid = qi.channel!

        raw_hash = Marten::HTTP::Params::Data::RawHash.new
        raw_hash["note"] = ["new note"]

        msg = capture_redis_message("socky:channel:antrikan:#{cid.hashed_id}") do
          result = Antrikan::QueuedItem::UpdaterService.new(
            qi,
            Marten::HTTP::Params::Data.new(raw_hash),
          ).run

          result.success?.should be_true
        end

        qi.reload
        qi.note.should eq "new note"

        msg.should_not be_nil
        json = JSON.parse(msg.not_nil!)
        {"queued_item_updated", "queue_updated"}.should contain(json["type"].as_s)
      end

      it "transitions status and publishes event" do
        qi = create_queued_item(
          status: Antrikan::QueueStatus::QUEUED,
        )
        cid = qi.channel!

        raw_hash = Marten::HTTP::Params::Data::RawHash.new
        raw_hash["status"] = ["attended"]

        msg = capture_redis_message("socky:channel:antrikan:#{cid.hashed_id}") do
          result = Antrikan::QueuedItem::UpdaterService.new(
            qi,
            Marten::HTTP::Params::Data.new(raw_hash),
          ).run

          result.success?.should be_true
        end

        qi.reload
        qi.status.should eq Antrikan::QueueStatus::ATTENDED.value

        msg.should_not be_nil
        json = JSON.parse(msg.not_nil!)
        {"queued_item_updated", "queue_updated"}.should contain(json["type"].as_s)
      end
    end

    context "with invalid schema" do
      it "returns failure for empty data" do
        qi = create_queued_item
        raw_hash = Marten::HTTP::Params::Data::RawHash.new

        result = Antrikan::QueuedItem::UpdaterService.new(
          qi,
          Marten::HTTP::Params::Data.new(raw_hash),
        ).run

        result.success?.should be_false
      end
    end
  end
end
