require "../spec_helper"

describe Ligo::PasswordResetConfirmHandler do
  context "with a valid token" do
    it "sets the new password and clears the reset token" do
      user = create_user(password: "OldPassword01")
      token = user.generate_password_reset_token
      user.save!

      response = Marten::Spec.client.post(
        Marten.routes.reverse("reset_password_confirm"),
        data: {
          hashed_id: user.hashed_id,
          token:     token,
          password1: "NewPassword01",
          password2: "NewPassword01",
        }.to_json,
        content_type: "application/json"
      )

      response.status.should eq 200
      json_response = JSON.parse(response.content)
      json_response["jwt_token"].should_not be_nil

      user.reload
      user.reset_password_token.should be_nil
      user.reset_password_token_created_at.should be_nil
      MartenAuth.authenticate(user.email!, "NewPassword01").should eq user
    end
  end

  context "when the passwords do not match" do
    it "returns 422" do
      user = create_user
      token = user.generate_password_reset_token
      user.save!

      response = Marten::Spec.client.post(
        Marten.routes.reverse("reset_password_confirm"),
        data: {
          hashed_id: user.hashed_id,
          token:     token,
          password1: "NewPassword01",
          password2: "SomethingElse01",
        }.to_json,
        content_type: "application/json"
      )

      response.status.should eq 422
    end
  end

  context "when the token is invalid" do
    it "returns 422" do
      user = create_user
      user.generate_password_reset_token
      user.save!

      response = Marten::Spec.client.post(
        Marten.routes.reverse("reset_password_confirm"),
        data: {
          hashed_id: user.hashed_id,
          token:     "wrong-token",
          password1: "NewPassword01",
          password2: "NewPassword01",
        }.to_json,
        content_type: "application/json"
      )

      response.status.should eq 422
    end
  end

  context "when the token has expired" do
    it "returns 422" do
      user = create_user
      token = user.generate_password_reset_token
      user.reset_password_token_created_at = Time.utc - 1.hour
      user.save!

      response = Marten::Spec.client.post(
        Marten.routes.reverse("reset_password_confirm"),
        data: {
          hashed_id: user.hashed_id,
          token:     token,
          password1: "NewPassword01",
          password2: "NewPassword01",
        }.to_json,
        content_type: "application/json"
      )

      response.status.should eq 422
    end
  end
end
