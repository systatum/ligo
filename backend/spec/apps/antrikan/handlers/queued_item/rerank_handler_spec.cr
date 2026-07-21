require "./spec_helper"

describe Antrikan::QueuedItemRerankHandler do
  context "when the request payload is valid" do
    it "reranks queued items by setting rank and reranked_at" do
      ctx = create_authorized_queue_item
      queue = ctx[:queue]
      user = ctx[:user]
      item_a = ctx[:queued_item]
      item_b = create_queued_item(queue: queue, item: create_item(channel: queue.channel!))
      item_c = create_queued_item(queue: queue, item: create_item(channel: queue.channel!))

      payload = {
        items: [
          {slug: item_a.slug!, rank: 2},
          {slug: item_b.slug!, rank: 0},
          {slug: item_c.slug!, rank: 1},
        ],
        timestamp: Time.utc,
      }

      response = Marten::Spec.client.patch(
        Marten.routes.reverse(
          "antrikan:queue:item:rerank",
          queue_slug: queue.slug!
        ),
        data: payload.to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 200

      item_a.reload
      item_b.reload
      item_c.reload

      item_a.rank.should eq 2
      item_b.rank.should eq 0
      item_c.rank.should eq 1

      item_a.reranked_at.should_not be_nil
      item_b.reranked_at.should_not be_nil
      item_c.reranked_at.should_not be_nil
    end

    it "allows first-time rerank when reranked_at is nil" do
      ctx = create_authorized_queue_item
      queue = ctx[:queue]
      user = ctx[:user]
      qi = ctx[:queued_item]

      qi.rank.should be_nil
      qi.reranked_at.should be_nil

      payload = {
        items: [
          {slug: qi.slug!, rank: 0},
        ],
        timestamp: 1.hour.ago,
      }

      response = Marten::Spec.client.patch(
        Marten.routes.reverse(
          "antrikan:queue:item:rerank",
          queue_slug: queue.slug!
        ),
        data: payload.to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 200

      qi.reload
      qi.rank.should eq 0
      qi.reranked_at.should_not be_nil
    end
  end

  context "when OLDORDER conflict occurs" do
    it "returns 422 when any item has reranked_at >= timestamp" do
      ctx = create_authorized_queue_item
      queue = ctx[:queue]
      user = ctx[:user]
      qi = ctx[:queued_item]

      recent_time = Time.utc
      qi.rank = 3
      qi.reranked_at = recent_time
      qi.save!

      payload = {
        items: [
          {slug: qi.slug!, rank: 0},
        ],
        timestamp: recent_time,
      }

      response = Marten::Spec.client.patch(
        Marten.routes.reverse(
          "antrikan:queue:item:rerank",
          queue_slug: queue.slug!
        ),
        data: payload.to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 422
    end

    it "succeeds when reranked_at is older than timestamp" do
      ctx = create_authorized_queue_item
      queue = ctx[:queue]
      user = ctx[:user]
      qi = ctx[:queued_item]

      qi.rank = 3
      qi.reranked_at = 1.hour.ago
      qi.save!

      payload = {
        items: [
          {slug: qi.slug!, rank: 0},
        ],
        timestamp: Time.utc,
      }

      response = Marten::Spec.client.patch(
        Marten.routes.reverse(
          "antrikan:queue:item:rerank",
          queue_slug: queue.slug!
        ),
        data: payload.to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 200

      qi.reload
      qi.rank.should eq 0
    end
  end

  context "when the request payload is invalid" do
    it "rejects unauthenticated request" do
      ctx = create_authorized_queue_item
      queue = ctx[:queue]
      qi = ctx[:queued_item]

      payload = {
        items: [
          {slug: qi.slug!, rank: 0},
        ],
        timestamp: Time.utc,
      }

      response = Marten::Spec.client.patch(
        Marten.routes.reverse(
          "antrikan:queue:item:rerank",
          queue_slug: queue.slug!
        ),
        data: payload.to_json,
        content_type: "application/json"
      )

      response.status.should eq 403
    end

    it "rejects authenticated user from different organization" do
      organization = create_organization
      owner = create_user(organization: organization)
      space = create_space(manager: owner)
      channel = create_channel(space: space)
      queue = create_queue(channel: channel, queuer: create_queuer(space: space))
      qi = create_queued_item(queue: queue, item: create_item(channel: channel))
      outsider = create_user(organization: create_organization)

      payload = {
        items: [
          {slug: qi.slug!, rank: 0},
        ],
        timestamp: Time.utc,
      }

      response = Marten::Spec.client.patch(
        Marten.routes.reverse(
          "antrikan:queue:item:rerank",
          queue_slug: queue.slug!
        ),
        data: payload.to_json,
        headers: {authorization: "Bearer #{outsider.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 403
    end

    it "returns 422 when items array is empty" do
      ctx = create_authorized_queue_item
      queue = ctx[:queue]
      user = ctx[:user]

      payload = {
        items:     [] of NamedTuple(slug: String, rank: Int32),
        timestamp: Time.utc,
      }

      response = Marten::Spec.client.patch(
        Marten.routes.reverse(
          "antrikan:queue:item:rerank",
          queue_slug: queue.slug!
        ),
        data: payload.to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 422
    end

    it "returns 422 when an item slug does not belong to the queue" do
      ctx = create_authorized_queue_item
      queue = ctx[:queue]
      user = ctx[:user]
      other_channel = create_channel
      other_queue = create_queue(channel: other_channel)
      other_item = create_queued_item(queue: other_queue, item: create_item(channel: other_channel))

      payload = {
        items: [
          {slug: other_item.slug!, rank: 0},
        ],
        timestamp: Time.utc,
      }

      response = Marten::Spec.client.patch(
        Marten.routes.reverse(
          "antrikan:queue:item:rerank",
          queue_slug: queue.slug!
        ),
        data: payload.to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 422
    end

    it "returns 422 when timestamp is missing" do
      ctx = create_authorized_queue_item
      queue = ctx[:queue]
      user = ctx[:user]
      qi = ctx[:queued_item]

      payload = {
        items: [
          {slug: qi.slug!, rank: 0},
        ],
      }

      response = Marten::Spec.client.patch(
        Marten.routes.reverse(
          "antrikan:queue:item:rerank",
          queue_slug: queue.slug!
        ),
        data: payload.to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 422
    end
  end

  context "when publishing events to redis" do
    it "publishes queued_item_updated for each reranked item" do
      ctx = create_authorized_queue_item
      queue = ctx[:queue]
      user = ctx[:user]
      item_a = ctx[:queued_item]
      item_b = create_queued_item(queue: queue, item: create_item(channel: queue.channel!))
      cid = queue.channel!

      payload = {
        items: [
          {slug: item_a.slug!, rank: 0},
          {slug: item_b.slug!, rank: 1},
        ],
        timestamp: Time.utc,
      }

      messages = capture_redis_messages("socky:channel:antrikan:#{cid.hashed_id}", 2) do
        response = Marten::Spec.client.patch(
          Marten.routes.reverse(
            "antrikan:queue:item:rerank",
            queue_slug: queue.slug!
          ),
          data: payload.to_json,
          headers: {authorization: "Bearer #{user.jwt_token}"},
          content_type: "application/json"
        )

        response.status.should eq 200
      end

      messages.size.should eq 2
      messages.each do |msg|
        json = JSON.parse(msg)
        json["type"].as_s.should eq "queued_item_updated"
      end
    end
  end
end
