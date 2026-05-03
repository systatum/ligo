require "../../spec_helper"

describe Workaty::CandidateCreateHandler do
  context "when given all fields" do
    it "creates a new candidate" do
      user = create_user
      response = Marten::Spec.client.post(
        Marten.routes.reverse("workaty:candidate:create"),
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

    it "allows blank email twice" do
      user = create_user
      Marten::Spec.client.post(
        Marten.routes.reverse("workaty:candidate:create"),
        data: {
          first_name: "John",
          last_name:  "Doe",
          fitness:    Workaty::Candidate::Fitness::UNKNOWN.to_s,
        }.to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response = Marten::Spec.client.post(
        Marten.routes.reverse("workaty:candidate:create"),
        data: {
          first_name: "Jane",
          last_name:  "Doe",
          fitness:    Workaty::Candidate::Fitness::UNKNOWN.to_s,
        }.to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 200

      cand = Workaty::Candidate.last!
      cand.organization.should eq user.organization
      cand.first_name.should eq "Jane"
      cand.last_name.should eq "Doe"
      cand.fitness.should eq Workaty::Candidate::Fitness::UNKNOWN
      cand.email.should eq ""
      cand.created_at.should_not be_nil
      cand.updated_at.should_not be_nil
      cand.deleted_at.should be_nil

      response.content.should eq Workaty::CandidateSerializer.serialize(cand)
    end

    it "allows leaving out fitness field" do
      user = create_user
      response = Marten::Spec.client.post(
        Marten.routes.reverse("workaty:candidate:create"),
        data: {
          first_name: "Lorem",
          last_name:  "Ipsum",
        }.to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 200

      cand = Workaty::Candidate.last!
      cand.organization.should eq user.organization
      cand.first_name.should eq "Lorem"
      cand.last_name.should eq "Ipsum"
      cand.fitness.should eq Workaty::Candidate::Fitness::UNKNOWN
      cand.email.should eq ""
      cand.created_at.should_not be_nil
      cand.updated_at.should_not be_nil
      cand.deleted_at.should be_nil

      response.content.should eq Workaty::CandidateSerializer.serialize(cand)

      Workaty::Candidate.filter(fitness: cand.fitness).count.should eq 1
    end

    context "with invalid fitness value" do
      it "raises an error" do
        user = create_user
        invalid_fitness = "POTENTIAL_FIT"
        response = Marten::Spec.client.post(
          Marten.routes.reverse("workaty:candidate:create"),
          data: {
            first_name: "Lorem",
            last_name:  "Ipsum",
            fitness:    invalid_fitness,
          }.to_json,
          headers: {authorization: "Bearer #{user.jwt_token}"},
          content_type: "application/json"
        )

        response.status.should eq 422
        response.content.should eq({
          error: {
            messages: ["Fitness: #{invalid_fitness} is not one of the accepted values."],
          },
        }.to_json)

        Workaty::Candidate.filter(fitness: invalid_fitness).count.should eq 0
      end
    end
  end
end
