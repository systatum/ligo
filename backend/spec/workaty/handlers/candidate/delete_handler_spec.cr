require "../../../spec_helper"

describe Workaty::CandidateDeleteHandler do
  describe "#delete" do
    context "when the user is authorized to delete the record" do
      it "can be deleted" do
        u = create_user
        c = create_candidate(adder: u)
        c.deleted_at.should be_nil

        response = Marten::Spec.client.delete(
          Marten.routes.reverse("workaty:api_candidate_delete", candidate_slug: c.slug!),
          headers: {authorization: "Bearer #{u.jwt_token}"},
        )

        response.status.should eq 200

        c_deleted = Workaty::Candidate.unscoped.get!(id: c.id)
        c_deleted.id.should eq c.id
        c_deleted.deleted_at.should be_a Time

        response.content.should eq Workaty::CandidateSerializer.serialize(c_deleted)
      end
    end

    context "when the user belongs to a different organization" do
      it "will not be deleted" do
        u = create_user
        other_u = create_user
        c = create_candidate(adder: u)
        c.deleted_at.should be_nil

        response = Marten::Spec.client.delete(
          Marten.routes.reverse("workaty:api_candidate_delete", candidate_slug: c.slug!),
          headers: {authorization: "Bearer #{other_u.jwt_token}"},
        )

        response.status.should eq 404
        response.content.should eq({error: {messages: ["Not found"]}}.to_json)

        c.reload
        c.deleted_at.should be_nil
      end
    end

    context "when the user is not authorized to delete the record" do
      it "renders 403 and keep record intact" do
        u = create_user
        less_authorized_u = create_user organization: u.organization!, role: Auth::Role::SECURITY_STAFF
        c = create_candidate(adder: u)
        c.deleted_at.should be_nil

        response = Marten::Spec.client.delete(
          Marten.routes.reverse("workaty:api_candidate_delete", candidate_slug: c.slug!),
          headers: {authorization: "Bearer #{less_authorized_u.jwt_token}"},
        )

        response.status.should eq 403
        response.content.should eq({error: {messages: ["Not authorized"]}}.to_json)

        c.reload
        c.deleted_at.should be_nil
      end
    end
  end
end
