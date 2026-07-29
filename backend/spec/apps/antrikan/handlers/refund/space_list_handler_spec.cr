require "./spec_helper"

describe Antrikan::RefundSpaceListHandler do
  context "when the requester owns the space" do
    it "lists refunds across every channel/queue/payment in the space" do
      owner = create_user
      space = create_space(manager: owner)
      first_channel = create_channel(space: space)
      second_channel = create_channel(space: space)

      first_payment = create_payment(queue: create_queue(space: space), amount: BigFloat.new(50))
      second_payment = create_payment(queue: create_queue(space: space), amount: BigFloat.new(70))

      first_refund = create_refund(payment: first_payment, amount: BigFloat.new(5))
      second_refund = create_refund(payment: second_payment, amount: BigFloat.new(7))

      other_space_refund = create_refund

      response = Marten::Spec.client.get(
        Marten.routes.reverse("antrikan:space:refund_list", space_hashed_id: space.hashed_id),
        headers: {authorization: "Bearer #{owner.jwt_token}"},
      )

      response.status.should eq 200

      body = JSON.parse(response.content)
      ids = body.as_a.map(&.["id"].as_s)

      ids.size.should eq 2
      ids.should contain first_refund.id.to_s
      ids.should contain second_refund.id.to_s
      ids.should_not contain other_space_refund.id.to_s
    end
  end

  context "when the requester does not own the space" do
    it "returns 403" do
      space = create_space
      outsider = create_user

      response = Marten::Spec.client.get(
        Marten.routes.reverse("antrikan:space:refund_list", space_hashed_id: space.hashed_id),
        headers: {authorization: "Bearer #{outsider.jwt_token}"},
      )

      response.status.should eq 403
    end
  end
end
