require "./spec_helper"

describe Antrikan::RefundAcceptHandler do
  context "when the requester owns the refund's queue's space" do
    it "accepts the refund" do
      owner = create_user
      space = create_space(manager: owner)
      queue = create_queue(space: space)
      payment = create_payment(queue: queue, amount: BigFloat.new(100))
      refund = create_refund(payment: payment, amount: BigFloat.new(10))

      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:refund:accept", refund_slug: refund.slug!),
        data: {review_note: "confirmed with customer"}.to_json,
        headers: {authorization: "Bearer #{owner.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 200

      refund.reload
      refund.status!.should eq Antrikan::RefundStatus::ACCEPTED.value
      refund.reviewed_by_id.should eq owner.id
      refund.review_note.should eq "confirmed with customer"

      response.content.should eq Antrikan::RefundSerializer.serialize(refund, viewer_is_staff: true)
    end

    it "returns 422 when accepting would leave a negative balance and it isn't forceful" do
      owner = create_user
      space = create_space(manager: owner)
      queue = create_queue(space: space)
      payment = create_payment(queue: queue, amount: BigFloat.new(100))
      create_refund(payment: payment, amount: BigFloat.new(90), status: Antrikan::RefundStatus::ACCEPTED)
      refund = create_refund(payment: payment, amount: BigFloat.new(50))

      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:refund:accept", refund_slug: refund.slug!),
        data: ({} of String => String).to_json,
        headers: {authorization: "Bearer #{owner.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 422

      refund.reload
      refund.status!.should eq Antrikan::RefundStatus::PENDING.value
    end
  end

  context "when the requester does not own the refund's queue's space" do
    it "returns 403" do
      refund = create_refund
      outsider = create_user

      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:refund:accept", refund_slug: refund.slug!),
        data: ({} of String => String).to_json,
        headers: {authorization: "Bearer #{outsider.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 403
    end
  end
end
