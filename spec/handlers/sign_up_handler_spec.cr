require "../spec_helper"

describe Ligo::SignUpHandler do
  raw_client_key = "test_raw_client_key"

  context "when the email has never been registered" do
    context "with never-registered organization" do
      it "registers a new account associated to the email, assigning the realm's default role" do
        realm = create_realm(api_client_key: raw_client_key, default_role: Role::OWNER)

        response = Marten::Spec.client.post(
          Marten.routes.reverse("sign_up"),
          data: {
            realm_id:          realm.id,
            api_client_key:    raw_client_key,
            organization_name: "Awesome Company",
            email:             "custy@systatum.com",
            password:          "Password01",
            first_name:        "Adam",
            last_name:         "Hakarsa",
          }.to_json,
          content_type: "application/json"
        )

        user = Ligo::User.last!
        user.email.should eq "custy@systatum.com"
        user.first_name.should eq "Adam"
        user.last_name.should eq "Hakarsa"
        user.role!.should eq Role::OWNER
        MartenAuth.authenticate(user.email!, "Password01").should eq user

        response.status.should eq 200
        response.content.should eq UserSerializer.serialize(user)
      end
    end

    context "with an existing organization" do
      it "joins that organization immediately, keeping the default staff role" do
        realm = create_realm(api_client_key: raw_client_key, default_role: Role::OWNER)
        existing_organization = create_organization

        response = Marten::Spec.client.post(
          Marten.routes.reverse("sign_up"),
          data: {
            realm_id:        realm.id,
            api_client_key:  raw_client_key,
            organization_id: existing_organization.hashed_id,
            email:           "custy@systatum.com",
            password:        "Password01",
            first_name:      "Adam",
            last_name:       "Hakarsa",
          }.to_json,
          content_type: "application/json"
        )

        user = Ligo::User.last!
        user.organization.should eq existing_organization
        user.email.should eq "custy@systatum.com"
        user.first_name.should eq "Adam"
        user.last_name.should eq "Hakarsa"
        user.role!.should eq Role::FULL_TIME_STAFF
        MartenAuth.authenticate(user.email!, "Password01").should eq user

        response.status.should eq 200
        response.content.should eq UserSerializer.serialize(user)
      end
    end

    context "with a missing realm_id" do
      it "does not allow for registration" do
        response = Marten::Spec.client.post(
          Marten.routes.reverse("sign_up"),
          data: {
            organization_name: "Awesome Company",
            api_client_key:    raw_client_key,
            email:             "custy@systatum.com",
            password:          "Password01",
            first_name:        "Adam",
            last_name:         "Hakarsa",
          }.to_json,
          content_type: "application/json"
        )

        response.status.should eq 422
      end
    end

    context "with an unknown realm_id" do
      it "does not allow for registration" do
        response = Marten::Spec.client.post(
          Marten.routes.reverse("sign_up"),
          data: {
            realm_id:          "unknown_realm",
            api_client_key:    raw_client_key,
            organization_name: "Awesome Company",
            email:             "custy@systatum.com",
            password:          "Password01",
            first_name:        "Adam",
            last_name:         "Hakarsa",
          }.to_json,
          content_type: "application/json"
        )

        response.status.should eq 422
      end
    end

    context "with an invalid api_client_key" do
      it "does not allow for registration" do
        realm = create_realm(api_client_key: raw_client_key)

        response = Marten::Spec.client.post(
          Marten.routes.reverse("sign_up"),
          data: {
            realm_id:          realm.id,
            api_client_key:    "not_the_real_client_key",
            organization_name: "Awesome Company",
            email:             "custy@systatum.com",
            password:          "Password01",
            first_name:        "Adam",
            last_name:         "Hakarsa",
          }.to_json,
          content_type: "application/json"
        )

        response.status.should eq 422
      end
    end
  end

  context "when the email has been used for registration" do
    it "does not allow for registration" do
      realm = create_realm(api_client_key: raw_client_key)
      email = "custy@systatum.com"
      user = create_user(email: email)
      user.should_not be_nil

      response = Marten::Spec.client.post(
        Marten.routes.reverse("sign_up"),
        data: {
          realm_id:          realm.id,
          api_client_key:    raw_client_key,
          organization_name: "Awesome Company",
          email:             email,
          password:          "Password01",
          first_name:        "Adam",
          last_name:         "Hakarsa",
        }.to_json,
        content_type: "application/json"
      )

      response.status.should eq 422
      response.content.should eq({error: {messages: ["Email: Already taken."]}}.to_json)
    end
  end
end
