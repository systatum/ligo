require "./spec_helper"

describe Antrikan::SpaceDeleteHandler do
  context "when the user is authorized" do
    it "soft deletes the space" do
      user = create_user
      space = create_space(manager: user)
      space_id = space.id!

      response = Marten::Spec.client.delete(
        Marten.routes.reverse("antrikan:space:delete", space_hashed_id: space.hashed_id),
        headers: {authorization: "Bearer #{user.jwt_token}"}
      )

      response.status.should eq 200

      deleted_space = Antrikan::Space.unscoped.get!(id: space_id)
      deleted_space.deleted_at.should be_a Time

      response.content.should eq Antrikan::SpaceSerializer.serialize(deleted_space)
    end

    it "returns the deleted space" do
      user = create_user
      space = create_space(manager: user)

      response = Marten::Spec.client.delete(
        Marten.routes.reverse("antrikan:space:delete", space_hashed_id: space.hashed_id),
        headers: {authorization: "Bearer #{user.jwt_token}"}
      )

      response.status.should eq 200
      response.content.should contain space.hashed_id
    end

    context "when the space belongs to another user" do
      it "will not be deleted" do
        user1 = create_user
        user2 = create_user
        space = create_space(manager: user2)

        response = Marten::Spec.client.delete(
          Marten.routes.reverse("antrikan:space:delete", space_hashed_id: space.hashed_id),
          headers: {authorization: "Bearer #{user1.jwt_token}"}
        )

        response.status.should eq 403
        response.content.should eq({error: {messages: ["Not authorized"]}}.to_json)

        space.reload
        space.deleted_at.should be_nil
      end
    end
  end

  context "when the user is not authorized" do
    it "returns 400" do
      user = create_user
      space = create_space(manager: user)

      response = Marten::Spec.client.delete(
        Marten.routes.reverse("antrikan:space:delete", space_hashed_id: space.hashed_id)
      )

      response.status.should eq 400
    end
  end
end
