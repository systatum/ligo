require "./spec_helper"

describe Antrikan::Item::UpdaterService do
  describe "#run" do
    context "when order changes" do
      it "publishes item_updated event" do
        item = create_item(order: 1)
        cid = item.channel!

        raw_hash = Marten::HTTP::Params::Data::RawHash.new
        raw_hash["order"] = [JSON.parse("5")]

        msg = capture_redis_message("socky:channel:antrikan:#{cid.hashed_id}") do
          result = Antrikan::Item::UpdaterService.new(
            item,
            Marten::HTTP::Params::Data.new(raw_hash),
          ).run

          result.success?.should be_true
        end

        item.reload
        item.order.should eq 5

        msg.should_not be_nil
        json = JSON.parse(msg.not_nil!)
        json["type"].as_s.should eq "item_updated"
        json["channel_id"].as_s.should eq cid.hashed_id
        json["item"]["order"].as_i.should eq 5
      end
    end

    context "when order does not change" do
      it "does not publish item_updated" do
        item = create_item(order: 1, name: "Old Name")
        cid = item.channel!

        raw_hash = Marten::HTTP::Params::Data::RawHash.new
        raw_hash["name"] = ["New Name"]

        expect_no_redis_message("socky:channel:antrikan:#{cid.hashed_id}") do
          result = Antrikan::Item::UpdaterService.new(
            item,
            Marten::HTTP::Params::Data.new(raw_hash),
          ).run

          result.success?.should be_true
        end

        item.reload
        item.name.should eq "New Name"
      end
    end
  end
end
