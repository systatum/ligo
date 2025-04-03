require "../../../spec_helper"

describe Workaty::CandidateShowHandler do
  describe "#show" do
    it "renders the fields" do
      user = create_user
      cand = create_candidate adder: user

      response = Marten::Spec.client.get(
        Marten.routes.reverse("workaty:api_candidate_show", candidate_slug: cand.slug!),
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json",
      )

      response.status.should eq 200
      json_response = JSON.parse(response.content)
      json_response["id"].as_s.should eq cand.slug
      json_response["first_name"].as_s.should eq cand.first_name
      json_response["last_name"].as_s.should eq cand.last_name
      json_response["fitness"].as_s.should eq "unknown"
      json_response["degrees"].should eq [] of String
      json_response["created_at"].as_s.should match date_time_format
      json_response["updated_at"].as_s.should match date_time_format
      json_response["deleted_at"].should eq nil

      response.content.should eq Workaty::CandidateSerializer.serialize(cand)
    end

    context "when having degrees" do
      it "renders all the visible degrees" do
        user = create_user
        cand = create_candidate adder: user
        degree1 = create_degree candidate: cand, institution: "MIT", major_field: "Economics"
        degree2 = create_degree candidate: cand, institution: "Harvard", major_field: "Physics", level: Workaty::Degree::Level::MASTER

        response = Marten::Spec.client.get(
          Marten.routes.reverse("workaty:api_candidate_show", candidate_slug: cand.slug!),
          headers: {authorization: "Bearer #{user.jwt_token}"},
          content_type: "application/json",
        )

        response.status.should eq 200
        json_response = JSON.parse(response.content)
        degrees = json_response["degrees"]

        # check the first degree manually
        degrees[0]["id"].should eq degree1.hashed_id
        degrees[0]["institution"].as_s.should eq "MIT"
        degrees[0]["level"].as_s.should eq "bachelor"
        degrees[0]["field"]["major"].as_s.should eq "Economics"
        degrees[0]["obtained_at"].should eq nil
        degrees[0]["created_at"].as_s.should match date_time_format
        degrees[0]["updated_at"].as_s.should match date_time_format
        degrees[0]["deleted_at"].should eq nil

        # check the second degree manually
        degrees[1]["id"].should eq degree2.hashed_id
        degrees[1]["institution"].as_s.should eq "Harvard"
        degrees[1]["level"].as_s.should eq "master"
        degrees[1]["field"]["major"].as_s.should eq "Physics"
        degrees[1]["obtained_at"].should eq nil
        degrees[1]["created_at"].as_s.should match date_time_format
        degrees[1]["updated_at"].as_s.should match date_time_format
        degrees[1]["deleted_at"].should eq nil
      end
    end
  end
end
