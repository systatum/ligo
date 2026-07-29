require "./spec_helper"

describe Antrikan::QueuedItem::UpdaterService do
  describe "#run" do
    context "with valid update" do
      it "updates note and publishes event" do
        qi = create_queued_item(note: "old note")
        cid = qi.channel!
        org_id = qi.queue!.space!.manager!.organization_id

        raw = Marten::HTTP::Params::Data::RawHash.new
        items_json = JSON.parse([{id: qi.id.to_s, note: "new note"}].to_json)
        raw["items"] = [items_json]

        msg = capture_redis_message("socky:channel:antrikan:#{cid.hashed_id}") do
          result = Antrikan::QueuedItem::UpdaterService.new(
            org_id.to_s,
            Marten::HTTP::Params::Data.new(raw),
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
        org_id = qi.queue!.space!.manager!.organization_id

        raw = Marten::HTTP::Params::Data::RawHash.new
        items_json = JSON.parse([{id: qi.id.to_s, status: "attended"}].to_json)
        raw["items"] = [items_json]

        msg = capture_redis_message("socky:channel:antrikan:#{cid.hashed_id}") do
          result = Antrikan::QueuedItem::UpdaterService.new(
            org_id.to_s,
            Marten::HTTP::Params::Data.new(raw),
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
        org_id = qi.queue!.space!.manager!.organization_id
        raw = Marten::HTTP::Params::Data::RawHash.new

        result = Antrikan::QueuedItem::UpdaterService.new(
          org_id.to_s,
          Marten::HTTP::Params::Data.new(raw),
        ).run

        result.success?.should be_false
      end

      it "returns failure instead of raising when items is not an array" do
        qi = create_queued_item
        org_id = qi.queue!.space!.manager!.organization_id

        raw = Marten::HTTP::Params::Data::RawHash.new
        raw["items"] = [JSON.parse({id: qi.id.to_s}.to_json)]

        result = Antrikan::QueuedItem::UpdaterService.new(
          org_id.to_s,
          Marten::HTTP::Params::Data.new(raw),
        ).run

        result.success?.should be_false
      end
    end
  end
end
