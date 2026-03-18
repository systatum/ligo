require "./spec_helper"

describe Antrikan::OperatingHourIndexHandler do
  describe "#get" do
    context "when the user is authorized" do
      it "returns all operating hours for a space" do
        user = create_user
        space = create_space(owner: user)
        op_hour1 = create_operating_hour(space: space, day: 1)
        op_hour2 = create_operating_hour(space: space, day: 2)

        response = Marten::Spec.client.get(
          Marten.routes.reverse("antrikan:space:operating_hour:index", space_hashed_id: space.hashed_id),
          headers: {authorization: "Bearer #{user.jwt_token}"}
        )

        response.status.should eq 200

        op_hours = Antrikan::OperatingHour.filter(space: space).map do |op_hour|
          Antrikan::OperatingHourSerializer.soft_serialize(op_hour)
        end

        parsed = JSON.parse(response.content)
        response.content.should eq({
          op_hours: op_hours,
        }.to_json)
      end

      it "does not return operating hours from other spaces" do
        user = create_user
        space1 = create_space(owner: user)
        space2 = create_space(owner: user)
        op_hour1 = create_operating_hour(space: space1, day: 1)
        op_hour2 = create_operating_hour(space: space2, day: 1)

        response = Marten::Spec.client.get(
          Marten.routes.reverse("antrikan:space:operating_hour:index", space_hashed_id: space1.hashed_id),
          headers: {authorization: "Bearer #{user.jwt_token}"}
        )

        response.status.should eq 200
        response.content.should contain op_hour1.hashed_id
        response.content.should_not contain op_hour2.hashed_id
      end

      it "does not return soft-deleted operating hours" do
        user = create_user
        space = create_space(owner: user)
        op_hour1 = create_operating_hour(space: space, day: 1)
        op_hour2 = create_operating_hour(space: space, day: 2)
        op_hour2.soft_delete!

        response = Marten::Spec.client.get(
          Marten.routes.reverse("antrikan:space:operating_hour:index", space_hashed_id: space.hashed_id),
          headers: {authorization: "Bearer #{user.jwt_token}"}
        )

        response.status.should eq 200
        response.content.should contain op_hour1.hashed_id
        response.content.should_not contain op_hour2.hashed_id
      end
    end

    context "when the user is not authorized" do
      it "returns 400" do
        user = create_user
        space = create_space(owner: user)

        response = Marten::Spec.client.get(
          Marten.routes.reverse("antrikan:space:operating_hour:index", space_hashed_id: space.hashed_id)
        )

        response.status.should eq 400
      end
    end
  end
end
