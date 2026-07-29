require "./spec_helper"

describe Antrikan::RefundCreateHandler do
  context "with a valid amount within the payment's remaining balance" do
    it "creates a pending refund" do
      queue = create_queue(payment_status: Antrikan::PaymentStatus::FULL)
      payment = create_payment(queue: queue, amount: BigFloat.new(100))
      requester = create_user

      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:payment:refund:create", payment_hashed_id: payment.hashed_id),
        data: {amount: "40", reason: "too many"}.to_json,
        headers: {authorization: "Bearer #{requester.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 201

      refund = Antrikan::Refund.last!
      refund.payment_id.should eq payment.id
      refund.requested_by_id.should eq requester.id
      refund.status!.should eq Antrikan::RefundStatus::PENDING.value

      response.content.should eq Antrikan::RefundSerializer.serialize(refund)
    end
  end

  context "when the queue is unpaid" do
    it "returns 422" do
      queue = create_queue(payment_status: Antrikan::PaymentStatus::UNPAID)
      payment = create_payment(queue: queue, amount: BigFloat.new(100))

      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:payment:refund:create", payment_hashed_id: payment.hashed_id),
        data: {amount: "10"}.to_json,
        content_type: "application/json"
      )

      response.status.should eq 422
      Antrikan::Refund.filter(payment_id: payment.id!).exists?.should be_false
    end
  end

  context "when the requested amount would leave a negative balance" do
    it "returns 422 without forceful" do
      queue = create_queue(payment_status: Antrikan::PaymentStatus::FULL)
      payment = create_payment(queue: queue, amount: BigFloat.new(100))

      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:payment:refund:create", payment_hashed_id: payment.hashed_id),
        data: {amount: "150"}.to_json,
        content_type: "application/json"
      )

      response.status.should eq 422
      Antrikan::Refund.filter(payment_id: payment.id!).exists?.should be_false
    end

    it "creates the refund when forceful is true" do
      queue = create_queue(payment_status: Antrikan::PaymentStatus::FULL)
      payment = create_payment(queue: queue, amount: BigFloat.new(100))

      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:payment:refund:create", payment_hashed_id: payment.hashed_id),
        data: {amount: "150", forceful: true}.to_json,
        content_type: "application/json"
      )

      response.status.should eq 201

      refund = Antrikan::Refund.last!
      refund.forceful!.should be_true
    end
  end
end
