require "./spec_helper"

describe Antrikan::RefundShowHandler do
  context "when the requester owns the refund's queue's space" do
    it "returns the refund, including review_note" do
      owner = create_user
      space = create_space(manager: owner)
      queue = create_queue(space: space)
      payment = create_payment(queue: queue, amount: BigFloat.new(100))
      refund = create_refund(
        payment: payment,
        amount: BigFloat.new(10),
        status: Antrikan::RefundStatus::ACCEPTED,
        reviewed_by: create_user,
        review_note: "Confirmed with customer",
      )

      response = Marten::Spec.client.get(
        Marten.routes.reverse("antrikan:refund:show", refund_slug: refund.slug!),
        headers: {authorization: "Bearer #{owner.jwt_token}"},
      )

      response.status.should eq 200
      response.content.should eq Antrikan::RefundSerializer.serialize(refund, viewer_is_staff: true)

      body = JSON.parse(response.content)
      body["review_note"].as_s.should eq "Confirmed with customer"
    end
  end

  context "when the requester does not own the refund's queue's space" do
    it "returns the refund, with review_note hidden" do
      refund = create_refund(
        status: Antrikan::RefundStatus::ACCEPTED,
        reviewed_by: create_user,
        review_note: "Confirmed with customer",
      )
      outsider = create_user

      response = Marten::Spec.client.get(
        Marten.routes.reverse("antrikan:refund:show", refund_slug: refund.slug!),
        headers: {authorization: "Bearer #{outsider.jwt_token}"},
      )

      response.status.should eq 200
      response.content.should eq Antrikan::RefundSerializer.serialize(refund, viewer_is_staff: false)

      body = JSON.parse(response.content)
      body["review_note"].as_nil.should be_nil
    end
  end

  context "when there is no authenticated requester at all" do
    it "returns the refund, with review_note hidden" do
      refund = create_refund(
        status: Antrikan::RefundStatus::ACCEPTED,
        reviewed_by: create_user,
        review_note: "Confirmed with customer",
      )

      response = Marten::Spec.client.get(
        Marten.routes.reverse("antrikan:refund:show", refund_slug: refund.slug!),
      )

      response.status.should eq 200

      body = JSON.parse(response.content)
      body["review_note"].as_nil.should be_nil
    end
  end

  context "when the refund does not exist" do
    it "returns 404" do
      response = Marten::Spec.client.get(
        Marten.routes.reverse("antrikan:refund:show", refund_slug: "UNKNOWN0"),
      )

      response.status.should eq 404
    end
  end
end
