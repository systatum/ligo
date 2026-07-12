require "../spec_helper"

describe Auth::MyBioShowHandler do
  context "when user is authenticated" do
    it "returns the current user's bio data" do
      user = create_user

      response = Marten::Spec.client.get(
        Marten.routes.reverse("auth:api_my_bio_show"),
        headers: {authorization: "Bearer #{user.jwt_token}"}
      )

      response.status.should eq 200
      response.content.should eq Auth::UserSerializer.serialize(user)
    end
  end

  context "when user is not authenticated" do
    it "returns 403 forbidden" do
      response = Marten::Spec.client.get(
        Marten.routes.reverse("auth:api_my_bio_show")
      )

      response.status.should eq 403
    end
  end
end
