require "./spec_helper"

describe Antrikan::SpaceShowHandler do
  context "when the user is authorized" do
    it "returns the space details" do
      user = create_user
      space = create_space(manager: user, name: "My Space")

      response = Marten::Spec.client.get(
        Marten.routes.reverse("antrikan:space:show", space_hashed_id: space.hashed_id),
        headers: {authorization: "Bearer #{user.jwt_token}"}
      )

      response.status.should eq 200
      response.content.should eq Antrikan::SpaceSerializer.serialize(space)
    end

    it "can find a space by code" do
      user = create_user
      space = create_space(manager: user, name: "My Space")

      response = Marten::Spec.client.get(
        Marten.routes.reverse("antrikan:space:code:show", space_code: space.code!),
        headers: {authorization: "Bearer #{user.jwt_token}"}
      )

      response.status.should eq 200
      response.content.should eq Antrikan::SpaceSerializer.serialize(space)
    end

    it "returns 404 when space does not exist" do
      user = create_user
      # Use a valid hash format that won't match any record
      fake_hashed_id = IdConcealer.encode(999999999)

      response = Marten::Spec.client.get(
        Marten.routes.reverse("antrikan:space:show", space_hashed_id: fake_hashed_id),
        headers: {authorization: "Bearer #{user.jwt_token}"}
      )

      response.status.should eq 404
    end

    it "returns 403 when space belongs to another user" do
      user1 = create_user
      user2 = create_user
      space = create_space(manager: user2, name: "Other User Space")

      response = Marten::Spec.client.get(
        Marten.routes.reverse("antrikan:space:show", space_hashed_id: space.hashed_id),
        headers: {authorization: "Bearer #{user1.jwt_token}"}
      )

      response.status.should eq 403
    end
  end

  context "when the user is not authorized" do
    it "returns 400 when not authenticated" do
      user = create_user
      space = create_space(manager: user)

      response = Marten::Spec.client.get(
        Marten.routes.reverse("antrikan:space:show", space_hashed_id: space.hashed_id)
      )

      response.status.should eq 400
    end
  end
end
