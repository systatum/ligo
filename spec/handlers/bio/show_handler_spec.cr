require "../../spec_helper"

describe Ligo::BioShowHandler do
  context "when user is authenticated" do
    it "returns the current user's bio data" do
      user = create_user

      response = Marten::Spec.client.get(
        Marten.routes.reverse("bio_show"),
        headers: {authorization: "Bearer #{user.jwt_token}"}
      )

      response.status.should eq 200
      response.content.should eq UserSerializer.serialize(user)
    end
  end

  context "when user is not authenticated" do
    it "returns 403 forbidden" do
      response = Marten::Spec.client.get(
        Marten.routes.reverse("bio_show")
      )

      response.status.should eq 403
    end
  end

  context "when only is given" do
    it "returns the public bio data of the given users, unauthenticated" do
      path = Marten.routes.reverse("bio_show")
      first_user = create_user
      second_user = create_user

      response = Marten::Spec.client.get("#{path}?only=#{first_user.hashed_id},#{second_user.hashed_id}")

      response.status.should eq 200
      response.content.should eq [
        PublicUserSerializer.soft_serialize(first_user),
        PublicUserSerializer.soft_serialize(second_user),
      ].to_json
    end

    it "ignores unresolvable hashed ids" do
      path = Marten.routes.reverse("bio_show")
      user = create_user

      response = Marten::Spec.client.get("#{path}?only=#{user.hashed_id},not-a-real-id")

      response.status.should eq 200
      response.content.should eq [PublicUserSerializer.soft_serialize(user)].to_json
    end
  end
end
