require "./spec_helper"

describe Antrikan::RefundListHandler do
  context "when the requester owns the payment's queue's space" do
    it "lists the payment's non-deleted refunds" do
      owner = create_user
      space = create_space(manager: owner)
      queue = create_queue(space: space)
      payment = create_payment(queue: queue, amount: BigFloat.new(100))
      kept = create_refund(payment: payment, amount: BigFloat.new(10))
      deleted = create_refund(payment: payment, amount: BigFloat.new(20))
      deleted.deleted_at = Time.utc
      deleted.save!

      response = Marten::Spec.client.get(
        Marten.routes.reverse("antrikan:payment:refund:list", payment_hashed_id: payment.hashed_id),
        headers: {authorization: "Bearer #{owner.jwt_token}"},
      )

      response.status.should eq 200
      response.content.should eq([Antrikan::RefundSerializer.soft_serialize(kept, viewer_is_staff: true)].to_json)
    end
  end

  context "when the requester does not own the payment's queue's space" do
    it "returns 403" do
      payment = create_payment
      outsider = create_user

      response = Marten::Spec.client.get(
        Marten.routes.reverse("antrikan:payment:refund:list", payment_hashed_id: payment.hashed_id),
        headers: {authorization: "Bearer #{outsider.jwt_token}"},
      )

      response.status.should eq 403
    end
  end
end
