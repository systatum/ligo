require "./spec_helper"

describe Antrikan::OperatingHourDeleteHandler do
  describe "#delete" do
    context "when the user is authorized to delete the record" do
      it "can be deleted" do
        user = create_user
        space = create_space(owner: user)
        op_hour = create_operating_hour(space: space, day: 1)
        op_hour_id = op_hour.id!

        response = Marten::Spec.client.delete(
          Marten.routes.reverse("antrikan:space:operating_hour:delete",
            space_hashed_id: space.hashed_id,
            operating_hour_hashed_id: op_hour.hashed_id
          ),
          headers: {authorization: "Bearer #{user.jwt_token}"}
        )

        response.status.should eq 200

        deleted_op_hour = Antrikan::OperatingHour.unscoped.get!(id: op_hour_id)
        deleted_op_hour.deleted_at.should be_a Time

        response.content.should eq Antrikan::OperatingHourSerializer.serialize(deleted_op_hour)
      end
    end

    context "when the operating hour belongs to another space" do
      it "will not be deleted" do
        user = create_user
        space1 = create_space(owner: user)
        space2 = create_space(owner: user)
        op_hour = create_operating_hour(space: space2, day: 1)

        response = Marten::Spec.client.delete(
          Marten.routes.reverse("antrikan:space:operating_hour:delete",
            space_hashed_id: space1.hashed_id,
            operating_hour_hashed_id: op_hour.hashed_id
          ),
          headers: {authorization: "Bearer #{user.jwt_token}"}
        )

        response.status.should eq 404
      end
    end

    context "when the user is not authorized" do
      it "returns 400" do
        user = create_user
        space = create_space(owner: user)
        op_hour = create_operating_hour(space: space, day: 1)

        response = Marten::Spec.client.delete(
          Marten.routes.reverse("antrikan:space:operating_hour:delete",
            space_hashed_id: space.hashed_id,
            operating_hour_hashed_id: op_hour.hashed_id
          )
        )

        response.status.should eq 400
      end
    end
  end
end
