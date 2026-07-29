require "./spec_helper"

describe Antrikan::PaymentCreateHandler do
  context "when the requester owns the queue's space" do
    it "creates a payment" do
      owner = create_user
      space = create_space(manager: owner)
      queue = create_queue(space: space)

      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:queue:payment:create", queue_slug: queue.slug!),
        data: {amount: "100", method: "cash"}.to_json,
        headers: {authorization: "Bearer #{owner.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 201

      payment = Antrikan::Payment.last!
      payment.queue_id.should eq queue.id
      payment.recorded_by_id.should eq owner.id

      response.content.should eq Antrikan::PaymentSerializer.serialize(payment)
    end
  end

  context "when the requester is a same-organization admin-tier staff member, not the owner" do
    it "creates a payment" do
      organization = create_organization
      manager = create_user(organization: organization)
      space = create_space(manager: manager)
      queue = create_queue(space: space)
      staff = create_user(organization: organization, role: Auth::Role::OPERATION_STAFF)

      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:queue:payment:create", queue_slug: queue.slug!),
        data: {amount: "100"}.to_json,
        headers: {authorization: "Bearer #{staff.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 201

      payment = Antrikan::Payment.last!
      payment.recorded_by_id.should eq staff.id
    end
  end

  context "when the requester does not own the queue's space" do
    it "returns 403" do
      queue = create_queue
      outsider = create_user

      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:queue:payment:create", queue_slug: queue.slug!),
        data: {amount: "100"}.to_json,
        headers: {authorization: "Bearer #{outsider.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 403
      Antrikan::Payment.filter(queue_id: queue.id!).exists?.should be_false
    end
  end

  context "when the requester is a same-organization staff member below the admin tier" do
    it "returns 403" do
      organization = create_organization
      manager = create_user(organization: organization)
      space = create_space(manager: manager)
      queue = create_queue(space: space)
      staff = create_user(organization: organization, role: Auth::Role::STAFF)

      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:queue:payment:create", queue_slug: queue.slug!),
        data: {amount: "100"}.to_json,
        headers: {authorization: "Bearer #{staff.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 403
      Antrikan::Payment.filter(queue_id: queue.id!).exists?.should be_false
    end
  end

  context "when amount is missing" do
    it "returns 422" do
      owner = create_user
      space = create_space(manager: owner)
      queue = create_queue(space: space)

      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:queue:payment:create", queue_slug: queue.slug!),
        data: ({} of String => String).to_json,
        headers: {authorization: "Bearer #{owner.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 422
    end
  end
end
