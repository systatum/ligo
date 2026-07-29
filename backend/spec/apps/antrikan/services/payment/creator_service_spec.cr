require "./spec_helper"

describe Antrikan::Payment::CreatorService do
  describe "#run" do
    context "with a valid amount" do
      it "creates a payment recorded by the given user" do
        queue = create_queue
        recorder = create_user

        raw_hash = Marten::HTTP::Params::Data::RawHash.new
        raw_hash["amount"] = ["100"]
        raw_hash["method"] = ["cash"]
        raw_hash["note"] = ["paid in full"]

        result = Antrikan::Payment::CreatorService.new(
          queue,
          Marten::HTTP::Params::Data.new(raw_hash),
          recorder,
        ).run

        result.success?.should be_true

        payment = result.data.not_nil!
        payment.queue_id.should eq queue.id
        payment.recorded_by_id.should eq recorder.id
        payment.amount.should eq "100"
        payment.method.should eq "cash"
        payment.note.should eq "paid in full"
      end
    end

    context "with a missing amount" do
      it "returns failure" do
        queue = create_queue
        raw_hash = Marten::HTTP::Params::Data::RawHash.new

        result = Antrikan::Payment::CreatorService.new(
          queue,
          Marten::HTTP::Params::Data.new(raw_hash),
          create_user,
        ).run

        result.success?.should be_false
      end
    end

    context "with a zero amount" do
      it "returns failure" do
        queue = create_queue
        raw_hash = Marten::HTTP::Params::Data::RawHash.new
        raw_hash["amount"] = ["0"]

        result = Antrikan::Payment::CreatorService.new(
          queue,
          Marten::HTTP::Params::Data.new(raw_hash),
          create_user,
        ).run

        result.success?.should be_false
      end
    end
  end
end
