require "./spec_helper"

describe Antrikan::RefundRejectHandler do
  context "when the requester owns the refund's queue's space" do
    it "rejects the refund" do
      owner = create_user
      space = create_space(manager: owner)
      queue = create_queue(space: space)
      payment = create_payment(queue: queue, amount: BigFloat.new(100))
      refund = create_refund(payment: payment, amount: BigFloat.new(10))

      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:refund:reject", refund_slug: refund.slug!),
        data: {review_note: "not eligible"}.to_json,
        headers: {authorization: "Bearer #{owner.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 200

      refund.reload
      refund.status!.should eq Antrikan::RefundStatus::REJECTED.value
      refund.reviewed_by_id.should eq owner.id

      response.content.should eq Antrikan::RefundSerializer.serialize(refund, viewer_is_staff: true)
    end
  end

  context "when the refund was already reviewed" do
    it "returns 422" do
      owner = create_user
      space = create_space(manager: owner)
      queue = create_queue(space: space)
      payment = create_payment(queue: queue, amount: BigFloat.new(100))
      refund = create_refund(payment: payment, amount: BigFloat.new(10), status: Antrikan::RefundStatus::REJECTED, reviewed_by: create_user)

      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:refund:reject", refund_slug: refund.slug!),
        data: ({} of String => String).to_json,
        headers: {authorization: "Bearer #{owner.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 422
    end
  end

  context "when the requester does not own the refund's queue's space" do
    it "returns 403" do
      refund = create_refund
      outsider = create_user

      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:refund:reject", refund_slug: refund.slug!),
        data: ({} of String => String).to_json,
        headers: {authorization: "Bearer #{outsider.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 403
    end
  end
end
