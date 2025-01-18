require "./spec_helper"

describe Auth::PasswordResetInitiateHandler do
  context "when given an email address" do
    it "sends a password reset email if user can be found" do
      user = create_user
      user.email.should_not be_nil

      response = Marten::Spec.client.post(
        Marten.routes.reverse("auth:api_request_password_reset"),
        data: {
          email: user.email,
        }.to_json,
        content_type: "application/json"
      )
      response.status.should eq 200

      Marten::Spec.delivered_emails.size.should eq 1
      Marten::Spec.delivered_emails[0].should be_a Auth::PasswordResetEmail
      Marten::Spec.delivered_emails[0].to[0].address.should eq user.email
    end

    it "does not send a password reset email if user can't be found" do
      response = Marten::Spec.client.post(
        Marten.routes.reverse("auth:api_request_password_reset"),
        data: {
          email: "not-found@example.com",
        }.to_json,
        content_type: "application/json",
      )
      response.status.should eq 200

      Marten::Spec.delivered_emails.should be_empty
    end
  end
end
