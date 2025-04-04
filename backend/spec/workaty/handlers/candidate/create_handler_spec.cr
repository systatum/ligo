require "../../../spec_helper"

describe Workaty::CandidateCreateHandler do
  describe "#post" do
    context "when given all fields" do
      it "creates a new candidate" do
        user = create_user
        response = Marten::Spec.client.post(
          Marten.routes.reverse("workaty:api_candidate_create"),
          data: {
            first_name: "Steve",
            last_name:  "Evets",
            fitness:    Workaty::Candidate::Fitness::GOOD_FIT.to_s,
          }.to_json,
          headers: {authorization: "Bearer #{user.jwt_token}"},
          content_type: "application/json"
        )

        response.status.should eq 200

        cand = Workaty::Candidate.last!
        cand.organization.should eq user.organization
        cand.first_name.should eq "Steve"
        cand.last_name.should eq "Evets"
        cand.fitness.should eq Workaty::Candidate::Fitness::GOOD_FIT
        cand.created_at.should_not be_nil
        cand.updated_at.should_not be_nil
        cand.deleted_at.should be_nil

        response.content.should eq Workaty::CandidateSerializer.serialize(cand)
      end
    end
  end
end
