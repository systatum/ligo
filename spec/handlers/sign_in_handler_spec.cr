require "../spec_helper"

describe Ligo::SignInHandler do
  context "when the email address can't be found" do
    it "complains of invalid credentials" do
      email = "me-not-found@systatum.com"
      Ligo::User.filter(email__iexact: email).count.should eq 0

      response = Marten::Spec.client.post(
        Marten.routes.reverse("sign_in"),
        data: {
          email:    email,
          password: "Password01",
        }.to_json,
        content_type: "application/json"
      )

      response.status.should eq 404
      response.content.should eq({error: {messages: ["Invalid credentials"]}}.to_json)
    end
  end

  context "when the password is wrong" do
    it "complains of invalid credentials" do
      password = "Password01"
      user = create_user(password: password)
      user.email.should_not be nil
      Ligo::User.filter(email__iexact: user.email).count.should eq 1

      response = Marten::Spec.client.post(
        Marten.routes.reverse("sign_in"),
        data: {
          email:    user.email,
          password: "wrong-#{password}",
        }.to_json,
        content_type: "application/json"
      )

      response.status.should eq 404
      response.content.should eq({error: {messages: ["Invalid credentials"]}}.to_json)
    end
  end

  context "when the password matches" do
    it "logs the user in" do
      password = "Password01"
      user = create_user(password: password)
      user.update!(is_email_address_verified: true)
      user.email.should_not be nil
      Ligo::User.filter(email__iexact: user.email).count.should eq 1

      response = Marten::Spec.client.post(
        Marten.routes.reverse("sign_in"),
        data: {
          email:    user.email,
          password: password,
        }.to_json,
        content_type: "application/json"
      )

      json_response = JSON.parse(response.content)
      response.status.should eq 200
      json_response["id"].as_s.should eq user.hashed_id
      json_response["email"].as_s.should eq user.email
      Ligo::User.find_by_jwt_token(json_response["jwt_token"].as_s).should eq user
      json_response["created_at"].as_s.should match date_time_format
      json_response["updated_at"].as_s.should match date_time_format
      json_response["deleted_at"].should eq nil
    end
  end
end
