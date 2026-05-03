require "./spec_helper"

describe Antrikan::SpaceIndexHandler do
  context "when the user is authorized" do
    context "with existing spaces" do
      it "returns all for current user" do
        user = create_user
        space1 = create_space(owner: user, name: "Space One")
        space2 = create_space(owner: user, name: "Space Two")

        response = Marten::Spec.client.get(
          Marten.routes.reverse("antrikan:space:index"),
          headers: {authorization: "Bearer #{user.jwt_token}"}
        )

        response.status.should eq 200

        spaces = Antrikan::Space.filter(owner: user).map do |space|
          Antrikan::SpaceSerializer.soft_serialize(space)
        end

        parsed = JSON.parse(response.content)
        response.content.should eq({
          spaces: spaces,
        }.to_json)
      end

      context "when a space belong to other user" do
        it "will not return it" do
          user1 = create_user
          user2 = create_user
          space1 = create_space(owner: user1, name: "User1 Space")
          space2 = create_space(owner: user2, name: "User2 Space")

          response = Marten::Spec.client.get(
            Marten.routes.reverse("antrikan:space:index"),
            headers: {authorization: "Bearer #{user1.jwt_token}"}
          )

          response.status.should eq 200
          response.content.should contain space1.hashed_id
          response.content.should_not contain space2.hashed_id
        end
      end
    end

    context "with deleted spaces" do
      it "will not return them" do
        user = create_user
        space1 = create_space(owner: user, name: "Active Space")
        space2 = create_space(owner: user, name: "Deleted Space")
        space2.soft_delete!

        response = Marten::Spec.client.get(
          Marten.routes.reverse("antrikan:space:index"),
          headers: {authorization: "Bearer #{user.jwt_token}"}
        )

        response.status.should eq 200
        response.content.should contain space1.hashed_id
        response.content.should_not contain space2.hashed_id
      end
    end
  end

  context "when the user is not authorized" do
    it "returns 400" do
      response = Marten::Spec.client.get(
        Marten.routes.reverse("antrikan:space:index")
      )

      response.status.should eq 400
    end
  end
end
