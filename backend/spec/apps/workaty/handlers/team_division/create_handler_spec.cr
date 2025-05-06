require "../../spec_helper"

describe Workaty::TeamDivisionCreateHandler do
  describe "#post" do
    context "with valid schema" do
      it "will create a new team division associated to the user's organization" do
        user = create_user

        response = Marten::Spec.client.post(
          Marten.routes.reverse("workaty:team_division:create"),
          data: {
            name: "HR",
          }.to_json,
          headers: {authorization: "Bearer #{user.jwt_token}"},
          content_type: "application/json"
        )

        response.status.should eq 200

        team_division = Workaty::TeamDivision.last!
        team_division.name.should eq "HR"
        team_division.organization.should eq user.organization
        team_division.created_at.should_not be_nil
        team_division.updated_at.should_not be_nil

        response.content.should eq Workaty::TeamDivisionSerializer.serialize(team_division)
      end

      context "with existing name" do
        it "will raise a unique constraint error" do
          user = create_user
          team_division = create_team_division(adder: user, name: "HR")

          response = Marten::Spec.client.post(
            Marten.routes.reverse("workaty:team_division:create"),
            data: {
              name: team_division.name,
            }.to_json,
            headers: {authorization: "Bearer #{user.jwt_token}"},
            content_type: "application/json"
          )

          response.status.should eq 400
          response.content.should eq({error: {messages: ["Name: must be unique"]}}.to_json)

          # try with lower case
          response = Marten::Spec.client.post(
            Marten.routes.reverse("workaty:team_division:create"),
            data: {
              name: team_division.name!.downcase,
            }.to_json,
            headers: {authorization: "Bearer #{user.jwt_token}"},
            content_type: "application/json"
          )

          response.status.should eq 400
          response.content.should eq({error: {messages: ["Name: must be unique"]}}.to_json)
        end

        context "when already deleted" do
          it "will create a new team division" do
            user = create_user
            team_division = create_team_division(adder: user, name: "HR")
            team_division.soft_delete!
            team_division.deleted_at.should_not be_nil

            response = Marten::Spec.client.post(
              Marten.routes.reverse("workaty:team_division:create"),
              data: {
                name: team_division.name,
              }.to_json,
              headers: {authorization: "Bearer #{user.jwt_token}"},
              content_type: "application/json"
            )

            response.status.should eq 200

            new_team_division = Workaty::TeamDivision.last!
            new_team_division.id.should_not eq team_division.id
            new_team_division.name.should eq "HR"
            new_team_division.organization.should eq user.organization
            new_team_division.created_at.should_not be_nil
            new_team_division.updated_at.should_not be_nil
            new_team_division.deleted_at.should be_nil

            response.content.should eq Workaty::TeamDivisionSerializer.serialize(new_team_division)
          end
        end

        context "when belong to a different organization" do
          it "can be created" do
            user = create_user
            other_user = create_user
            team_division = create_team_division(adder: user, name: "HR")

            response = Marten::Spec.client.post(
              Marten.routes.reverse("workaty:team_division:create"),
              data: {
                name: team_division.name,
              }.to_json,
              headers: {authorization: "Bearer #{other_user.jwt_token}"},
              content_type: "application/json"
            )

            response.status.should eq 200

            new_team_division = Workaty::TeamDivision.last!
            new_team_division.id.should_not eq team_division.id
            new_team_division.name.should eq team_division.name
            new_team_division.organization.should eq other_user.organization
            new_team_division.organization.should_not eq user.organization
            new_team_division.created_at.should_not be_nil
            new_team_division.updated_at.should_not be_nil
            new_team_division.deleted_at.should be_nil

            response.content.should eq Workaty::TeamDivisionSerializer.serialize(new_team_division)
          end
        end
      end
    end
  end
end
