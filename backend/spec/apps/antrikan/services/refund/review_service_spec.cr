require "./spec_helper"

describe Antrikan::Refund::ReviewService do
  describe "#run" do
    context "when accepting a pending refund within the payment's remaining balance" do
      it "accepts the refund and stamps the reviewer" do
        payment = create_payment(amount: BigFloat.new(100))
        refund = create_refund(payment: payment, amount: BigFloat.new(40))
        reviewer = create_user

        raw_hash = Marten::HTTP::Params::Data::RawHash.new
        raw_hash["review_note"] = ["looks legit"]

        result = Antrikan::Refund::ReviewService.new(
          refund,
          true,
          reviewer,
          Marten::HTTP::Params::Data.new(raw_hash),
        ).run

        result.success?.should be_true

        accepted = result.data.not_nil!
        accepted.status!.should eq Antrikan::RefundStatus::ACCEPTED.value
        accepted.reviewed_by_id.should eq reviewer.id
        accepted.reviewed_at.should_not be_nil
        accepted.review_note.should eq "looks legit"
      end
    end

    context "when accepting would leave the payment's balance negative" do
      it "rejects unless the refund was requested as forceful" do
        payment = create_payment(amount: BigFloat.new(100))
        create_refund(payment: payment, amount: BigFloat.new(80), status: Antrikan::RefundStatus::ACCEPTED)
        refund = create_refund(payment: payment, amount: BigFloat.new(50))

        raw_hash = Marten::HTTP::Params::Data::RawHash.new

        result = Antrikan::Refund::ReviewService.new(
          refund,
          true,
          create_user,
          Marten::HTTP::Params::Data.new(raw_hash),
        ).run

        result.success?.should be_false
        result.errors.not_nil![0].message.should eq Antrikan::ErrorCode::REFUND_NEGATIVE_BALANCE

        refund.reload
        refund.status!.should eq Antrikan::RefundStatus::PENDING.value
      end

      it "accepts anyway when the refund was requested as forceful" do
        payment = create_payment(amount: BigFloat.new(100))
        create_refund(payment: payment, amount: BigFloat.new(80), status: Antrikan::RefundStatus::ACCEPTED)
        refund = create_refund(payment: payment, amount: BigFloat.new(50), forceful: true)

        raw_hash = Marten::HTTP::Params::Data::RawHash.new

        result = Antrikan::Refund::ReviewService.new(
          refund,
          true,
          create_user,
          Marten::HTTP::Params::Data.new(raw_hash),
        ).run

        result.success?.should be_true
        result.data.not_nil!.status!.should eq Antrikan::RefundStatus::ACCEPTED.value
      end
    end

    context "when rejecting a pending refund" do
      it "does not require balance to be checked" do
        payment = create_payment(amount: BigFloat.new(100))
        create_refund(payment: payment, amount: BigFloat.new(80), status: Antrikan::RefundStatus::ACCEPTED)
        refund = create_refund(payment: payment, amount: BigFloat.new(50))

        raw_hash = Marten::HTTP::Params::Data::RawHash.new

        result = Antrikan::Refund::ReviewService.new(
          refund,
          false,
          create_user,
          Marten::HTTP::Params::Data.new(raw_hash),
        ).run

        result.success?.should be_true
        result.data.not_nil!.status!.should eq Antrikan::RefundStatus::REJECTED.value
      end
    end

    context "when the refund was already reviewed" do
      it "rejects reviewing it again" do
        refund = create_refund(status: Antrikan::RefundStatus::ACCEPTED, reviewed_by: create_user)

        raw_hash = Marten::HTTP::Params::Data::RawHash.new

        result = Antrikan::Refund::ReviewService.new(
          refund,
          false,
          create_user,
          Marten::HTTP::Params::Data.new(raw_hash),
        ).run

        result.success?.should be_false
        result.errors.not_nil![0].message.should eq Antrikan::ErrorCode::REFUND_ALREADY_REVIEWED
      end
    end
  end
end
