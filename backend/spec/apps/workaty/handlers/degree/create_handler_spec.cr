require "../../spec_helper"

describe Workaty::DegreeCreateHandler do
  describe "#post" do
    context "when given all fields" do
      context "when user and candidate are of the same organization" do
        it "will associate a new degree to a candidate" do
          user = create_user
          candidate = create_candidate(adder: user)

          response = Marten::Spec.client.post(
            Marten.routes.reverse("workaty:candidate:degree:create", candidate_slug: candidate.slug!),
            data: {
              institution: "Institution",
              level:       Workaty::Degree::Level::BACHELOR,
              major_field: "Computer Science",
            }.to_json,
            headers: {authorization: "Bearer #{user.jwt_token}"},
            content_type: "application/json"
          )

          response.status.should eq 200

          degree = Workaty::Degree.last!
          degree.candidate.should eq candidate
          degree.institution.should eq "Institution"
          degree.level.should eq Workaty::Degree::Level::BACHELOR
          degree.major_field.should eq "Computer Science"
          degree.created_at.should_not be_nil
          degree.updated_at.should_not be_nil

          response.content.should eq Workaty::DegreeSerializer.serialize(degree)
        end
      end

      context "when user and candidate aren't from the same organization" do
        it "will raise not found error" do
          user = create_user
          candidate = create_candidate

          response = Marten::Spec.client.post(
            Marten.routes.reverse("workaty:candidate:degree:create", candidate_slug: candidate.slug!),
            data: {
              institution: "Institution",
              level:       Workaty::Degree::Level::BACHELOR,
              major_field: "Computer Science",
            }.to_json,
            headers: {authorization: "Bearer #{user.jwt_token}"},
            content_type: "application/json"
          )

          response.status.should eq 404
          response.content.should eq({error: {messages: ["Not found"]}}.to_json)
        end
      end

      context "when the candidate can't be found" do
        it "will raise a not found error" do
          user = create_user

          response = Marten::Spec.client.post(
            Marten.routes.reverse("workaty:candidate:degree:create", candidate_slug: "not-real123"),
            data: {
              institution: "Institution",
              level:       Workaty::Degree::Level::BACHELOR,
              major_field: "Computer Science",
            }.to_json,
            headers: {authorization: "Bearer #{user.jwt_token}"},
            content_type: "application/json"
          )

          response.status.should eq 404
        end
      end
    end
  end
end
