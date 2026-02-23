require "./spec_helper"

describe Antrikan::SpaceUpdateHandler do
  describe "#patch" do
    context "when the user is authorized" do
      it "updates the space" do
        user = create_user
        space = create_space(user: user, name: "Original Name")

        response = Marten::Spec.client.patch(
          Marten.routes.reverse("antrikan:space:update", space_hashed_id: space.hashed_id),
          data: {name: "Updated Name"}.to_json,
          headers: {authorization: "Bearer #{user.jwt_token}"},
          content_type: "application/json"
        )

        response.status.should eq 200

        space.reload
        space.name.should eq "Updated Name"

        response.content.should eq Antrikan::SpaceSerializer.serialize(space)
      end

      it "updates optional fields" do
        user = create_user
        space = create_space(user: user, need_manual_approval: false, has_operating_hours: false)

        response = Marten::Spec.client.patch(
          Marten.routes.reverse("antrikan:space:update", space_hashed_id: space.hashed_id),
          data: {
            name:                 space.name,
            need_manual_approval: true,
            has_operating_hours:  true,
          }.to_json,
          headers: {authorization: "Bearer #{user.jwt_token}"},
          content_type: "application/json"
        )

        response.status.should eq 200

        space.reload
        space.need_manual_approval.should be_true
        space.has_operating_hours.should be_true
      end

      it "does not change the code" do
        user = create_user
        space = create_space(user: user)
        original_code = space.code!

        response = Marten::Spec.client.patch(
          Marten.routes.reverse("antrikan:space:update", space_hashed_id: space.hashed_id),
          data: {name: "New Name"}.to_json,
          headers: {authorization: "Bearer #{user.jwt_token}"},
          content_type: "application/json"
        )

        response.status.should eq 200

        space.reload
        space.code!.should eq original_code
      end

      it "returns 404 when space belongs to another user" do
        user1 = create_user
        user2 = create_user
        space = create_space(user: user2)

        response = Marten::Spec.client.patch(
          Marten.routes.reverse("antrikan:space:update", space_hashed_id: space.hashed_id),
          data: {name: "Hacked Name"}.to_json,
          headers: {authorization: "Bearer #{user1.jwt_token}"},
          content_type: "application/json"
        )

        response.status.should eq 404
      end
    end

    context "when the user is not authorized" do
      it "returns 400" do
        user = create_user
        space = create_space(user: user)

        response = Marten::Spec.client.patch(
          Marten.routes.reverse("antrikan:space:update", space_hashed_id: space.hashed_id),
          data: {name: "New Name"}.to_json,
          content_type: "application/json"
        )

        response.status.should eq 400
        space.reload
        space.name.should_not eq "New Name"
      end
    end
  end
end
