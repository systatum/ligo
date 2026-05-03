require "../../spec_helper"

describe Workaty::CandidateUpdateHandler do
  context "when the candidate cannot be found" do
    it "renders 404" do
      response = Marten::Spec.client.patch(
        Marten.routes.reverse("workaty:candidate:update", candidate_slug: "123"),
        data: {
          first_name: "Steve",
          last_name:  "Evets",
          fitness:    Workaty::Candidate::Fitness::GOOD_FIT.to_s,
        }.to_json,
        headers: {authorization: "Bearer #{create_user.jwt_token}"},
        content_type: "application/json",
      )

      response.status.should eq 404
      response.content.should eq({error: {messages: ["Not found"]}}.to_json)
    end
  end

  context "when the candidate can be found" do
    context "when the user is authorized" do
      context "when given unpermitted fields" do
        it "won't be updated" do
          user = create_user
          cand = create_candidate(
            adder: user,
            first_name: "A",
            last_name: "B",
            fitness: Workaty::Candidate::Fitness::UNKNOWN,
          )
          cand.first_name.should eq "A"
          cand.last_name.should eq "B"

          response = Marten::Spec.client.patch(
            Marten.routes.reverse("workaty:candidate:update", candidate_slug: cand.slug!),
            data: {name: "Steve"}.to_json,
            headers: {authorization: "Bearer #{user.jwt_token}"},
            content_type: "application/json",
          )

          response.status.should eq 422
          response.content.should eq({error: {messages: ["First name: Must be filled."]}}.to_json)
        end
      end

      it "will be updated" do
        user = create_user
        cand = create_candidate(
          adder: user,
          first_name: "A",
          last_name: "B",
          fitness: Workaty::Candidate::Fitness::UNKNOWN,
        )
        cand.first_name.should eq "A"
        cand.last_name.should eq "B"

        response = Marten::Spec.client.patch(
          Marten.routes.reverse("workaty:candidate:update", candidate_slug: cand.slug!),
          data: {
            first_name: "Steve",
            last_name:  "Evets",
            fitness:    "good_fit",
            note:       "This candidate is awesome",
            email:      "steve.evets@example.com",
            phone:      8155551234,
          }.to_json,
          headers: {authorization: "Bearer #{user.jwt_token}"},
          content_type: "application/json",
        )

        response.status.should eq 200

        cand.reload
        cand.first_name.should eq "Steve"
        cand.last_name.should eq "Evets"
        cand.fitness.should eq Workaty::Candidate::Fitness::GOOD_FIT
        cand.note.should eq "This candidate is awesome"
        cand.email.should eq "steve.evets@example.com"
        cand.phone.should eq 8155551234
        cand.updated_at.should_not eq cand.created_at
        cand.deleted_at.should be_nil

        response.content.should eq Workaty::CandidateSerializer.serialize(cand)
      end
    end

    context "when the user is not authorized to update" do
      it "won't be updated" do
        user = create_user
        cand = create_candidate(adder: user)
        original_first_name = cand.first_name
        original_last_name = cand.last_name
        original_fitness = cand.fitness
        other_user = create_user role: Auth::Role::SECURITY_STAFF

        response = Marten::Spec.client.patch(
          Marten.routes.reverse("workaty:candidate:update", candidate_slug: cand.slug!),
          data: {
            first_name: "A123",
            last_name:  "B456",
            fitness:    Workaty::Candidate::Fitness::GOOD_FIT.to_s,
          }.to_json,
          headers: {authorization: "Bearer #{other_user.jwt_token}"},
          content_type: "application/json",
        )

        response.status.should eq 403

        cand.reload
        cand.first_name.should eq original_first_name
        cand.last_name.should eq original_last_name
        cand.fitness.should eq original_fitness

        response.content.should eq({error: {messages: ["Not authorized"]}}.to_json)
      end
    end
  end
end
