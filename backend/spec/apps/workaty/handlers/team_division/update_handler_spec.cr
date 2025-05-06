require "../../spec_helper"

describe Workaty::TeamDivisionUpdateHandler do
  describe "#patch" do
    context "the team division cannot be found" do
      it "renders 404" do
        user = create_user

        response = Marten::Spec.client.patch(
          Marten.routes.reverse("workaty:team_division:update", team_division_hashed_id: "ABC"),
          data: {
            name: "HR",
          }.to_json,
          headers: {authorization: "Bearer #{user.jwt_token}"},
          content_type: "application/json",
        )

        response.status.should eq 404
        response.content.should eq({error: {messages: ["Not found"]}}.to_json)
      end
    end

    context "when the team division can be found" do
      context "when the user is authorized" do
        it "will be updated" do
          user = create_user
          team_division = create_team_division(adder: user)

          response = Marten::Spec.client.patch(
            Marten.routes.reverse("workaty:team_division:update", team_division_hashed_id: team_division.hashed_id),
            data: {
              name: "New Division",
            }.to_json,
            headers: {authorization: "Bearer #{user.jwt_token}"},
            content_type: "application/json",
          )

          response.status.should eq 200

          team_division.reload
          team_division.name.should eq "New Division"
          team_division.updated_at.should_not eq team_division.created_at
          team_division.deleted_at.should be_nil

          response.content.should eq Workaty::TeamDivisionSerializer.serialize(team_division)
        end
      end

      context "when the user belongs to a different organization" do
        it "won't be updated" do
          user = create_user
          other_user = create_user
          team_division = create_team_division(adder: user)

          response = Marten::Spec.client.patch(
            Marten.routes.reverse("workaty:team_division:update", team_division_hashed_id: team_division.hashed_id),
            data: {
              name: "New Division",
            }.to_json,
            headers: {authorization: "Bearer #{other_user.jwt_token}"},
            content_type: "application/json",
          )

          response.status.should eq 404
          response.content.should eq({error: {messages: ["Not found"]}}.to_json)

          team_division.reload
          team_division.name.should eq "HR"
        end
      end

      context "when the user is not authorized to update" do
        it "won't be updated" do
          user = create_user
          team_division = create_team_division(adder: user, name: "HR")
          other_user = create_user role: Auth::Role::SECURITY_STAFF

          response = Marten::Spec.client.patch(
            Marten.routes.reverse("workaty:team_division:update", team_division_hashed_id: team_division.hashed_id),
            data: {
              name: "New Division",
            }.to_json,
            headers: {authorization: "Bearer #{other_user.jwt_token}"},
            content_type: "application/json",
          )

          response.status.should eq 403

          team_division.reload
          team_division.name.should eq "HR"

          response.content.should eq({error: {messages: ["Not authorized"]}}.to_json)
        end
      end
    end
  end
end
