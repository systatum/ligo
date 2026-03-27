require "./spec_helper"

describe Auth::PasswordResetInitiateHandler do
  context "when given an email address" do
    it "enqueues a password reset email job if user can be found" do
      user = create_user
      user.email.should_not be_nil

      expect_jobs(Auth::User::PasswordResetInitiateJob, 1, "mailers") do
        response = Marten::Spec.client.post(
          Marten.routes.reverse("auth:api_request_password_reset"),
          data: {email: user.email.not_nil!}.to_json,
          content_type: "application/json"
        )
        response.status.should eq 200
      end
    end

    it "enqueues a job even if user can't be found" do
      expect_jobs(Auth::User::PasswordResetInitiateJob, 1, "mailers") do
        response = Marten::Spec.client.post(
          Marten.routes.reverse("auth:api_request_password_reset"),
          data: {email: "not-found@example.com"}.to_json,
          content_type: "application/json",
        )
        response.status.should eq 200
      end
    end
  end
end
