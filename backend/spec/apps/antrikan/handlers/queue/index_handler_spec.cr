require "./spec_helper"

describe Antrikan::QueueIndexHandler do
  context "when the request is valid" do
    it "returns queues for the selected channel only" do
      space = create_space
      channel = create_channel(space: space)
      other_channel = create_channel(space: space, name: "Other")

      q1 = create_queue(
        queuer: create_queuer(space: space),
        channel: channel,
        note: "First queue",
        status: Antrikan::QueueStatus::QUEUED,
        payment_status: Antrikan::PaymentStatus::UNPAID,
        total_price: 10_000_i64
      )
      q2 = create_queue(
        queuer: create_queuer(space: space),
        channel: channel,
        note: "Second queue",
        status: Antrikan::QueueStatus::ATTENDED,
        payment_status: Antrikan::PaymentStatus::PARTIAL,
        total_price: 25_000_i64
      )
      q3 = create_queue(
        queuer: create_queuer(space: space),
        channel: other_channel,
      )

      create_queued_item(queue: q1, channel: channel)
      create_queued_item(queue: q2, channel: channel)
      create_queued_item(queue: q3, channel: other_channel)

      response = Marten::Spec.client.get(
        Marten.routes.reverse("antrikan:channel:queue:index", channel_hashed_id: channel.hashed_id)
      )

      response.status.should eq 200

      json_response = JSON.parse(response.content)
      records = json_response["queues"].as_a
      records.size.should eq 2

      records[0]["id"].should eq q1.slug!
      records[0]["channel_id"].should eq q1.channel!.hashed_id
      records[0]["queuer_id"].should eq q1.queuer!.hashed_id
      records[0]["handler_id"].should eq nil
      records[0]["note"].should eq q1.note
      records[0]["status"].should eq q1.status
      records[0]["payment_status"].should eq q1.payment_status
      records[0]["total_price"].should eq q1.total_price

      records[1]["id"].should eq q2.slug!
      records[1]["channel_id"].should eq q2.channel!.hashed_id
      records[1]["queuer_id"].should eq q2.queuer!.hashed_id
      records[1]["handler_id"].should eq nil
      records[1]["note"].should eq q2.note
      records[1]["status"].should eq q2.status
      records[1]["payment_status"].should eq q2.payment_status
      records[1]["total_price"].should eq q2.total_price
    end

    it "filters by status when status query param is provided" do
      space = create_space
      channel = create_channel(space: space)
      queued = create_queue(
        queuer: create_queuer(space: space),
        channel: channel,
        status: Antrikan::QueueStatus::QUEUED
      )
      ready = create_queue(
        queuer: create_queuer(space: space),
        channel: channel,
        status: Antrikan::QueueStatus::READY
      )

      response = Marten::Spec.client.get(
        Marten.routes.reverse("antrikan:channel:queue:index", channel_hashed_id: channel.hashed_id),
        query_params: {status: "READY"}
      )

      response.status.should eq 200

      json_response = JSON.parse(response.content)
      records = json_response["queues"].as_a
      records.size.should eq 1

      records[0]["id"].should eq ready.slug!
      records[0]["status"].should eq Antrikan::QueueStatus::READY.value
    end

    it "filters by status enum name when status query param is provided" do
      space = create_space
      channel = create_channel(space: space)
      create_queue(
        queuer: create_queuer(space: space),
        channel: channel,
        status: Antrikan::QueueStatus::QUEUED
      )
      ready = create_queue(
        queuer: create_queuer(space: space),
        channel: channel,
        status: Antrikan::QueueStatus::READY
      )

      response = Marten::Spec.client.get(
        Marten.routes.reverse("antrikan:channel:queue:index", channel_hashed_id: channel.hashed_id),
        query_params: {status: "ready"}
      )

      response.status.should eq 200

      json_response = JSON.parse(response.content)
      records = json_response["queues"].as_a
      records.size.should eq 1
      records[0]["id"].should eq ready.slug!
    end

    it "returns 400 when status query param is invalid" do
      channel = create_channel

      response = Marten::Spec.client.get(
        Marten.routes.reverse("antrikan:channel:queue:index", channel_hashed_id: channel.hashed_id),
        query_params: {status: "invalid-status"}
      )

      response.status.should eq 400
    end
  end

  context "when the request is invalid" do
    it "returns 404 when channel does not exist" do
      response = Marten::Spec.client.get(
        Marten.routes.reverse("antrikan:channel:queue:index", channel_hashed_id: IdConcealer.encode(9_999_999))
      )

      response.status.should eq 404
    end
  end
end
