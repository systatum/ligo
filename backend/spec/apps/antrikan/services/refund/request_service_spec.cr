require "./spec_helper"

describe Antrikan::Refund::RequestService do
  describe "#run" do
    context "when the queue is UNPAID" do
      it "rejects the request" do
        queue = create_queue(payment_status: Antrikan::PaymentStatus::UNPAID)
        payment = create_payment(queue: queue, amount: BigFloat.new(100))

        raw_hash = Marten::HTTP::Params::Data::RawHash.new
        raw_hash["amount"] = ["10"]

        result = Antrikan::Refund::RequestService.new(
          payment,
          Marten::HTTP::Params::Data.new(raw_hash),
        ).run

        result.success?.should be_false
        result.errors.not_nil![0].message.should eq Antrikan::ErrorCode::PAYMENT_UNPAID
      end
    end

    context "when the projected balance would go negative" do
      it "rejects the request without forceful" do
        queue = create_queue(payment_status: Antrikan::PaymentStatus::FULL)
        payment = create_payment(queue: queue, amount: BigFloat.new(100))

        raw_hash = Marten::HTTP::Params::Data::RawHash.new
        raw_hash["amount"] = ["150"]

        result = Antrikan::Refund::RequestService.new(
          payment,
          Marten::HTTP::Params::Data.new(raw_hash),
        ).run

        result.success?.should be_false
        result.errors.not_nil![0].message.should eq Antrikan::ErrorCode::REFUND_NEGATIVE_BALANCE
        Antrikan::Refund.filter(payment_id: payment.id!).exists?.should be_false
      end

      it "creates the refund when forceful is true" do
        queue = create_queue(payment_status: Antrikan::PaymentStatus::FULL)
        payment = create_payment(queue: queue, amount: BigFloat.new(100))
        requester = create_user

        raw_hash = Marten::HTTP::Params::Data::RawHash.new
        raw_hash["amount"] = ["150"]
        raw_hash["forceful"] = [JSON.parse("true")]

        result = Antrikan::Refund::RequestService.new(
          payment,
          Marten::HTTP::Params::Data.new(raw_hash),
          requester,
        ).run

        result.success?.should be_true

        refund = result.data.not_nil!
        refund.forceful!.should be_true
        refund.status!.should eq Antrikan::RefundStatus::PENDING.value
        refund.requested_by_id.should eq requester.id
      end
    end

    context "when the balance stays non-negative" do
      it "creates the refund without needing forceful" do
        queue = create_queue(payment_status: Antrikan::PaymentStatus::PARTIAL)
        payment = create_payment(queue: queue, amount: BigFloat.new(100))

        raw_hash = Marten::HTTP::Params::Data::RawHash.new
        raw_hash["amount"] = ["40"]
        raw_hash["reason"] = ["customer request"]

        result = Antrikan::Refund::RequestService.new(
          payment,
          Marten::HTTP::Params::Data.new(raw_hash),
        ).run

        result.success?.should be_true

        refund = result.data.not_nil!
        refund.amount.should eq "40"
        refund.reason.should eq "customer request"
        refund.forceful!.should be_false
      end
    end

    context "with more than 2 images" do
      it "rejects the request" do
        queue = create_queue(payment_status: Antrikan::PaymentStatus::FULL)
        payment = create_payment(queue: queue, amount: BigFloat.new(100))

        raw_hash = Marten::HTTP::Params::Data::RawHash.new
        raw_hash["amount"] = ["10"]
        raw_hash["images"] = [
          JSON.parse({base64_bytes: Base64.encode(PNG_1X1), mimetype: "image/png"}.to_json),
          JSON.parse({base64_bytes: Base64.encode(PNG_1X1), mimetype: "image/png"}.to_json),
          JSON.parse({base64_bytes: Base64.encode(PNG_1X1), mimetype: "image/png"}.to_json),
        ]

        result = Antrikan::Refund::RequestService.new(
          payment,
          Marten::HTTP::Params::Data.new(raw_hash),
        ).run

        result.success?.should be_false
      end
    end

    context "with a missing amount" do
      it "returns failure" do
        queue = create_queue(payment_status: Antrikan::PaymentStatus::FULL)
        payment = create_payment(queue: queue, amount: BigFloat.new(100))
        raw_hash = Marten::HTTP::Params::Data::RawHash.new

        result = Antrikan::Refund::RequestService.new(
          payment,
          Marten::HTTP::Params::Data.new(raw_hash),
        ).run

        result.success?.should be_false
      end
    end
  end
end
