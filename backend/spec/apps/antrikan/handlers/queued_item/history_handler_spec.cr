require "./spec_helper"

describe Antrikan::QueuedItemHistoryHandler do
  context "when the request is authorized" do
    it "returns timeline with all reached states" do
      ctx = create_authorized_queue_item
      qi = ctx[:queued_item]
      user = ctx[:user]

      qi.attended_at = 1.hour.ago
      qi.packed_at = 30.minutes.ago
      qi.ready_at = 10.minutes.ago
      qi.status = Antrikan::QueueStatus::READY.value
      qi.save!

      response = Marten::Spec.client.get(
        Marten.routes.reverse(
          "antrikan:queued_item:history",
          queued_item_id: qi.id.to_s
        ),
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 200

      json = JSON.parse(response.content)
      json.as_a.size.should eq 4

      json[0]["state"].should eq "QUEUED"
      json[0]["time_taken_seconds"].as_i64.should eq 0

      json[1]["state"].should eq "ATTENDED"
      json[1]["time_taken_seconds"].as_i64.should be > 0

      json[2]["state"].should eq "PACKED"
      json[3]["state"].should eq "READY"
    end

    it "returns only queued state when no other states reached" do
      ctx = create_authorized_queue_item(status: Antrikan::QueueStatus::QUEUED)
      qi = ctx[:queued_item]
      user = ctx[:user]

      response = Marten::Spec.client.get(
        Marten.routes.reverse(
          "antrikan:queued_item:history",
          queued_item_id: qi.id.to_s
        ),
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 200

      json = JSON.parse(response.content)
      json.as_a.size.should eq 1
      json[0]["state"].should eq "QUEUED"
      json[0]["time_taken_seconds"].as_i64.should eq 0
    end

    it "includes canceled state for soft-deleted items" do
      ctx = create_authorized_queue_item(status: Antrikan::QueueStatus::QUEUED)
      qi = ctx[:queued_item]
      user = ctx[:user]

      qi.change_status!(:canceled)
      qi.save!

      response = Marten::Spec.client.get(
        Marten.routes.reverse(
          "antrikan:queued_item:history",
          queued_item_id: qi.id.to_s
        ),
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 200

      json = JSON.parse(response.content)
      json.as_a.size.should eq 2
      json[1]["state"].should eq "CANCELED"
    end
  end

  context "when the request is unauthorized" do
    it "rejects unauthenticated request" do
      qi = create_queued_item

      response = Marten::Spec.client.get(
        Marten.routes.reverse(
          "antrikan:queued_item:history",
          queued_item_id: qi.id.to_s
        ),
        content_type: "application/json"
      )

      response.status.should eq 403
    end

    it "rejects user from different organization" do
      ctx = create_authorized_queue_item
      qi = ctx[:queued_item]
      outsider = create_user(organization: create_organization)

      response = Marten::Spec.client.get(
        Marten.routes.reverse(
          "antrikan:queued_item:history",
          queued_item_id: qi.id.to_s
        ),
        headers: {authorization: "Bearer #{outsider.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 403
    end

    it "returns 404 for non-existent queued item" do
      user = create_user

      response = Marten::Spec.client.get(
        Marten.routes.reverse(
          "antrikan:queued_item:history",
          queued_item_id: UUID.random.to_s
        ),
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 404
    end
  end
end
