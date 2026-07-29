require "./spec_helper"

describe Antrikan::PaymentListHandler do
  context "when the requester owns the queue's space" do
    it "lists the queue's non-deleted payments" do
      owner = create_user
      space = create_space(manager: owner)
      queue = create_queue(space: space)
      kept = create_payment(queue: queue, amount: BigFloat.new(50))
      deleted = create_payment(queue: queue, amount: BigFloat.new(30))
      deleted.deleted_at = Time.utc
      deleted.save!

      response = Marten::Spec.client.get(
        Marten.routes.reverse("antrikan:queue:payment:list", queue_slug: queue.slug!),
        headers: {authorization: "Bearer #{owner.jwt_token}"},
      )

      response.status.should eq 200
      response.content.should eq([Antrikan::PaymentSerializer.soft_serialize(kept)].to_json)
    end
  end

  context "when the requester does not own the queue's space" do
    it "returns 403" do
      queue = create_queue
      outsider = create_user

      response = Marten::Spec.client.get(
        Marten.routes.reverse("antrikan:queue:payment:list", queue_slug: queue.slug!),
        headers: {authorization: "Bearer #{outsider.jwt_token}"},
      )

      response.status.should eq 403
    end
  end
end
