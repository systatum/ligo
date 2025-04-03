require "../../../spec_helper"

describe Workaty::DegreeUpdateHandler do
  describe "#patch" do
    context "when the degree cannot be found" do
      it "renders 404" do
        user = create_user
        candidate = create_candidate(adder: user)

        response = Marten::Spec.client.patch(
          Marten.routes.reverse("workaty:api_degree_update", candidate_slug: candidate.slug!, degree_hashed_id: "123"),
          data: {
            institution: "Institution",
            level:       Workaty::Degree::Level::BACHELOR,
            major_field: "Computer Science",
          }.to_json,
          headers: {authorization: "Bearer #{create_user.jwt_token}"},
          content_type: "application/json",
        )

        response.status.should eq 404
        response.content.should eq({error: {messages: ["Not found"]}}.to_json)
      end
    end

    context "when the degree can be found" do
      context "when the user belongs to the same organization" do
        context "when the user is not authorized" do
          it "will raise not found error" do
            user = create_user
            other_user = create_user(organization: user.organization!, role: Auth::Role::SECURITY_STAFF)
            candidate = create_candidate(adder: user)
            degree = create_degree(candidate: candidate)

            response = Marten::Spec.client.patch(
              Marten.routes.reverse("workaty:api_degree_update", candidate_slug: candidate.slug!, degree_hashed_id: degree.hashed_id),
              data: {level: Workaty::Degree::Level::MASTER}.to_json,
              headers: {authorization: "Bearer #{other_user.jwt_token}"},
              content_type: "application/json",
            )

            response.status.should eq 403
            response.content.should eq({error: {messages: ["Not authorized"]}}.to_json)
          end
        end

        context "when the user is authorized" do
          it "will be updated" do
            user = create_user
            candidate = create_candidate(adder: user)
            degree = create_degree(
              candidate: candidate,
              institution: "Institution",
              level: Workaty::Degree::Level::BACHELOR,
              major_field: "Computer Science",
            )

            response = Marten::Spec.client.patch(
              Marten.routes.reverse("workaty:api_degree_update", candidate_slug: candidate.slug!, degree_hashed_id: degree.hashed_id),
              data: {
                institution: "Updated Institution",
                level:       Workaty::Degree::Level::MASTER,
                major_field: "Mathematics",
              }.to_json,
              headers: {authorization: "Bearer #{user.jwt_token}"},
              content_type: "application/json",
            )

            response.status.should eq 200

            degree.reload
            degree.institution.should eq "Updated Institution"
            degree.level.should eq Workaty::Degree::Level::MASTER
            degree.major_field.should eq "Mathematics"

            response.content.should eq Workaty::DegreeSerializer.serialize(degree)
          end
        end
      end

      context "when the current user does not belong to the same organization" do
        it "will raise not found error" do
          user = create_user
          candidate = create_candidate
          degree = create_degree(
            candidate: candidate,
            institution: "Institution",
            level: Workaty::Degree::Level::BACHELOR,
            major_field: "Computer Science",
          )

          response = Marten::Spec.client.patch(
            Marten.routes.reverse("workaty:api_degree_update", candidate_slug: candidate.slug!, degree_hashed_id: degree.hashed_id),
            data: {institution: "Updated Institution"}.to_json,
            headers: {authorization: "Bearer #{create_user.jwt_token}"},
            content_type: "application/json",
          )

          response.status.should eq 404
          response.content.should eq({error: {messages: ["Not found"]}}.to_json)
        end
      end
    end
  end
end
