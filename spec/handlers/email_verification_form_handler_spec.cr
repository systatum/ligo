require "../spec_helper"

describe Ligo::EmailVerificationFormHandler do
  context "when user param is missing" do
    it "returns 400" do
      path = Marten.routes.reverse("verify_email_form")
      response = Marten::Spec.client.get(path)

      response.status.should eq 400
      JSON.parse(response.content)["error"]["messages"].as_a.first.as_s.should contain("Missing user identifier")
    end
  end

  context "when user is not found" do
    it "returns 400" do
      path = Marten.routes.reverse("verify_email_form")
      response = Marten::Spec.client.get("#{path}?user=nonexistent")

      response.status.should eq 400
      JSON.parse(response.content)["error"]["messages"].as_a.first.as_s.should contain("User not found")
    end
  end

  context "when user is already verified" do
    it "responds with verified message" do
      user = create_user
      user.is_email_address_verified = true
      user.save!

      path = Marten.routes.reverse("verify_email_form")
      response = Marten::Spec.client.get("#{path}?user=#{user.hashed_id}")

      response.status.should eq 200
      response.content.should contain("Email address verified")
    end
  end

  context "when verification link is expired" do
    it "shows expired message and enqueues a new verification job" do
      user = create_user
      user.email_verification_token = "oldtoken"
      user.email_verification_token_created_at = Time.utc - 7200.seconds
      user.email_verification_token_expired_at = Time.utc - 3600.seconds
      user.save!

      expect_jobs(Ligo::User::EmailVerificationSendJob, 1, queue: "mailers") do
        path = Marten.routes.reverse("verify_email_form")
        response = Marten::Spec.client.get("#{path}?user=#{user.hashed_id}")

        response.status.should eq 200
        response.content.should contain("Verification link expired")
      end
    end
  end

  context "when verification is pending" do
    it "shows the verification form" do
      user = create_user
      user.generate_email_verification_token!(nil)
      user.save!

      path = Marten.routes.reverse("verify_email_form")
      response = Marten::Spec.client.get("#{path}?user=#{user.hashed_id}")

      response.status.should eq 200
      response.content.should contain("Enter verification code")
    end
  end
end
