require "./spec_helper"

describe Auth::SignUpHandler do
  context "when the email has never been registered" do
    context "with never-registered organization" do
      it "registers a new account associated to the email" do
        response = Marten::Spec.client.post(
          Marten.routes.reverse("auth:api_sign_up"),
          data: {
            organization_name: "Awesome Company",
            email:             "custy@custy.com",
            password:          "Password01",
            first_name:        "Adam",
            last_name:         "Hakarsa",
          }.to_json,
          content_type: "application/json"
        )

        user = Auth::User.last!
        user.email.should eq "custy@custy.com"
        user.first_name.should eq "Adam"
        user.last_name.should eq "Hakarsa"
        MartenAuth.authenticate(user.email!, "Password01").should eq user

        response.status.should eq 200
        response.content.should eq Auth::UserSerializer.serialize(user)
      end
    end

    context "with an existing organization" do
      it "joins that organization immediately" do
        existing_organization = create_organization

        response = Marten::Spec.client.post(
          Marten.routes.reverse("auth:api_sign_up"),
          data: {
            organization_id: existing_organization.hashed_id,
            email:           "custy@custy.com",
            password:        "Password01",
            first_name:      "Adam",
            last_name:       "Hakarsa",
          }.to_json,
          content_type: "application/json"
        )

        user = Auth::User.last!
        user.organization.should eq existing_organization
        user.email.should eq "custy@custy.com"
        user.first_name.should eq "Adam"
        user.last_name.should eq "Hakarsa"
        MartenAuth.authenticate(user.email!, "Password01").should eq user

        response.status.should eq 200
        response.content.should eq Auth::UserSerializer.serialize(user)
      end
    end
  end

  context "when the email has been used for registration" do
    it "does not allow for registration" do
      email = "custy@custy.com"
      user = create_user(email: email)
      user.should_not be_nil

      response = Marten::Spec.client.post(
        Marten.routes.reverse("auth:api_sign_up"),
        data: {
          organization_name: "Awesome Company",
          email:             email,
          password:          "Password01",
          first_name:        "Adam",
          last_name:         "Hakarsa",
        }.to_json,
        content_type: "application/json"
      )

      response.status.should eq 400
      response.content.should eq({error: {messages: ["Email: This address is taken"]}}.to_json)
    end
  end
end
