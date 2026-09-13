require "../spec_helper"

describe Ligo::PasswordUpdateHandler do
  context "when the old password is correct" do
    it "changes the token password last updated at field" do
      old_password = "Password01"
      new_password = "new #{old_password}"

      user = create_user(password: old_password)
      old_jwt_token = user.jwt_token

      response = Marten::Spec.client.post(
        Marten.routes.reverse("update_password"),
        data: {
          current_password:     old_password,
          new_password:         new_password,
          new_password_confirm: new_password,
        }.to_json,
        headers: {
          authorization: "Bearer #{old_jwt_token}",
        },
        content_type: "application/json",
      )
      response.status.should eq 200

      json_response = JSON.parse(response.content)
      json_response["jwt_token"].should_not be_nil

      received_jwt_token = json_response["jwt_token"].as_s
      decoded_received_jwt_token = Ligo::User.decode_jwt_token(received_jwt_token)
      decoded_old_jwt_token = Ligo::User.decode_jwt_token(old_jwt_token)
      decoded_received_jwt_token["puat"].as_f.should be > decoded_old_jwt_token["puat"].as_f
    end
  end

  context "when the old password is wrong" do
    it "does not proceed with updating the password" do
      user = create_user(password: "Password01")

      response = Marten::Spec.client.post(
        Marten.routes.reverse("update_password"),
        data: {
          current_password:     "123",
          new_password:         "456",
          new_password_confirm: "456",
        }.to_json,
        headers: {
          authorization: "Bearer #{user.jwt_token}",
        },
        content_type: "application/json"
      )

      response.status.should eq 422
      response.content.should eq({error: {messages: ["Current password: Invalid"]}}.to_json)
    end
  end

  context "when the password does not match the re-entry confirmation" do
    it "does not proceed with updating the password" do
      current_password = "Password01"
      user = create_user(password: current_password)

      response = Marten::Spec.client.post(
        Marten.routes.reverse("update_password"),
        data: {
          current_password:     current_password,
          new_password:         "123",
          new_password_confirm: "456",
        }.to_json,
        headers: {
          authorization: "Bearer #{user.jwt_token}",
        },
        content_type: "application/json"
      )

      response.status.should eq 422
      response.content.should eq({error: {messages: ["New password: Does not match to each other"]}}.to_json)
    end
  end
end
