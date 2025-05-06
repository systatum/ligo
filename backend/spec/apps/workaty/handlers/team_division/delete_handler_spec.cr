require "../../spec_helper"

describe Workaty::TeamDivisionDeleteHandler do
  describe "#delete" do
    context "when the user is authorized to delete the record" do
      it "can be deleted" do
        u = create_user
        td = create_team_division(adder: u)
        td.deleted_at.should be_nil

        response = Marten::Spec.client.delete(
          Marten.routes.reverse("workaty:team_division:delete", team_division_hashed_id: td.hashed_id),
          headers: {authorization: "Bearer #{u.jwt_token}"},
        )

        response.status.should eq 200

        td_deleted = Workaty::TeamDivision.unscoped.get!(id: td.id)
        td_deleted.id.should eq td.id
        td_deleted.deleted_at.should be_a Time

        response.content.should eq Workaty::TeamDivisionSerializer.serialize(td_deleted)
      end
    end

    context "when the user belongs to a different organization" do
      it "will not be deleted" do
        u = create_user
        other_u = create_user
        td = create_team_division(adder: u)
        td.deleted_at.should be_nil

        response = Marten::Spec.client.delete(
          Marten.routes.reverse("workaty:team_division:delete", team_division_hashed_id: td.hashed_id),
          headers: {authorization: "Bearer #{other_u.jwt_token}"},
        )

        response.status.should eq 404
        response.content.should eq({error: {messages: ["Not found"]}}.to_json)

        td.reload
        td.deleted_at.should be_nil
      end
    end
  end
end
