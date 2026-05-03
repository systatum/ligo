require "../../spec_helper"

describe Workaty::DegreeDeleteHandler do
  context "when the user is authorized to delete the record" do
    it "can be deleted" do
      user = create_user
      candidate = create_candidate(adder: user)
      degree = create_degree(candidate: candidate)
      degree.deleted_at.should be_nil

      response = Marten::Spec.client.delete(
        Marten.routes.reverse("workaty:candidate:degree:delete", candidate_slug: candidate.slug!, degree_hashed_id: degree.hashed_id),
        headers: {authorization: "Bearer #{user.jwt_token}"},
      )

      response.status.should eq 200

      degree_deleted = Workaty::Degree.unscoped.get!(id: degree.id)
      degree_deleted.id.should eq degree.id
      degree_deleted.deleted_at.should be_a Time

      response.content.should eq Workaty::DegreeSerializer.serialize(degree_deleted)
    end
  end

  context "when the user belongs to a different organization" do
    it "will not be deleted" do
      user = create_user
      other_user = create_user
      candidate = create_candidate(adder: user)
      degree = create_degree(candidate: candidate)
      degree.deleted_at.should be_nil

      response = Marten::Spec.client.delete(
        Marten.routes.reverse("workaty:candidate:degree:delete", candidate_slug: candidate.slug!, degree_hashed_id: degree.hashed_id),
        headers: {authorization: "Bearer #{other_user.jwt_token}"},
      )

      response.status.should eq 404
      response.content.should eq({error: {messages: ["Not found"]}}.to_json)

      degree.reload
      degree.deleted_at.should be_nil
    end
  end

  context "when the user is not authorized to delete the record" do
    it "will render 403 and keeps record intact" do
      user = create_user
      less_authorized_user = create_user organization: user.organization!, role: Auth::Role::SECURITY_STAFF
      candidate = create_candidate(adder: user)
      degree = create_degree(candidate: candidate)
      degree.deleted_at.should be_nil

      response = Marten::Spec.client.delete(
        Marten.routes.reverse("workaty:candidate:degree:delete", candidate_slug: candidate.slug!, degree_hashed_id: degree.hashed_id),
        headers: {authorization: "Bearer #{less_authorized_user.jwt_token}"},
      )

      response.status.should eq 403
      response.content.should eq({error: {messages: ["Not authorized"]}}.to_json)

      degree.reload
      degree.deleted_at.should be_nil
    end
  end
end
