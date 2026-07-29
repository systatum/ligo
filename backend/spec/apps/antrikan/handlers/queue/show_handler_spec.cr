require "./spec_helper"

describe Antrikan::QueueShowHandler do
  it "returns queue by slug" do
    queue = create_queue(note: "Kitchen order")

    response = Marten::Spec.client.get(
      Marten.routes.reverse("antrikan:queue:show", queue_slug: queue.slug!)
    )

    response.status.should eq 200
  end

  it "returns all expected queue fields" do
    queue = create_queue(
      note: "all-fields",
      status: Antrikan::QueueStatus::ATTENDED,
      payment_status: Antrikan::PaymentStatus::PARTIAL,
      total_price: BigFloat.new(125_000),
      fully_paid_at: Time.utc
    )

    response = Marten::Spec.client.get(
      Marten.routes.reverse("antrikan:queue:show", queue_slug: queue.slug!)
    )

    response.status.should eq 200
    response.content.should eq Antrikan::QueueSerializer.serialize(queue)
  end

  it "returns 404 when queue is soft deleted" do
    queue = create_queue
    queue.soft_delete!

    response = Marten::Spec.client.get(
      Marten.routes.reverse("antrikan:queue:show", queue_slug: queue.slug!)
    )

    response.status.should eq 404
  end

  it "returns 404 when queue does not exist" do
    response = Marten::Spec.client.get(
      Marten.routes.reverse("antrikan:queue:show", queue_slug: "UNKNOWN00")
    )

    response.status.should eq 404
  end
end
