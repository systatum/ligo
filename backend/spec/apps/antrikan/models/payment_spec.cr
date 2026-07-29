require "../spec_helper"

describe "Antrikan::Payment" do
  describe "validations" do
    it "rejects a zero amount" do
      payment = create_payment

      payment.amount = "0"
      payment.valid?.should be_false
      payment.errors[:amount][0].message.should eq "must be greater than 0"
    end

    it "rejects a negative amount" do
      payment = create_payment

      payment.amount = "-5"
      payment.valid?.should be_false
    end

    it "allows a positive amount" do
      payment = create_payment(amount: BigFloat.new(50))

      payment.valid?.should be_true
    end
  end

  describe "#amount_refunded and #remaining_refundable_amount" do
    it "only counts accepted refunds" do
      payment = create_payment(amount: BigFloat.new(100))
      create_refund(payment: payment, amount: BigFloat.new(20), status: Antrikan::RefundStatus::ACCEPTED)
      create_refund(payment: payment, amount: BigFloat.new(30), status: Antrikan::RefundStatus::REJECTED)
      create_refund(payment: payment, amount: BigFloat.new(15), status: Antrikan::RefundStatus::PENDING)

      payment.amount_refunded.should eq BigFloat.new(20)
      payment.remaining_refundable_amount.should eq BigFloat.new(80)
    end

    it "ignores soft-deleted accepted refunds" do
      payment = create_payment(amount: BigFloat.new(100))
      accepted = create_refund(payment: payment, amount: BigFloat.new(20), status: Antrikan::RefundStatus::ACCEPTED)
      accepted.deleted_at = Time.utc
      accepted.save!

      payment.amount_refunded.should eq BigFloat.new(0)
      payment.remaining_refundable_amount.should eq BigFloat.new(100)
    end

    it "is the full amount when there are no refunds" do
      payment = create_payment(amount: BigFloat.new(75))

      payment.amount_refunded.should eq BigFloat.new(0)
      payment.remaining_refundable_amount.should eq BigFloat.new(75)
    end
  end
end
