require "../spec_helper"

describe Ligo::EmailVerifyHandler do
  context "when code param is missing" do
    it "returns 400" do
      path = Marten.routes.reverse("verify_email")
      response = Marten::Spec.client.get(path)

      response.status.should eq 400
      JSON.parse(response.content)["error"]["messages"].as_a.first.as_s.should contain("Missing verification code")
    end
  end

  context "with a valid user and code" do
    it "marks email as verified and clears token fields" do
      user = create_user
      user.generate_email_verification_token!(nil)
      user.save!

      path = Marten.routes.reverse("verify_email")
      response = Marten::Spec.client.get(
        "#{path}?code=#{user.email_verification_token}&user=#{user.hashed_id}"
      )

      response.status.should eq 200
      response.content.should contain("Email address verified")

      user.reload
      user.is_email_address_verified.should be_true
      user.email_verification_token.should be_nil
      user.email_verification_token_created_at.should be_nil
      user.email_verification_token_expired_at.should be_nil
    end

    it "redirects when redirectionUri is provided" do
      user = create_user
      user.generate_email_verification_token!(nil)
      user.save!

      path = Marten.routes.reverse("verify_email")
      response = Marten::Spec.client.get(
        "#{path}?code=#{user.email_verification_token}&user=#{user.hashed_id}&redirectionUri=https://example.com/callback"
      )

      response.status.should eq 302
      response.headers["Location"].should eq "https://example.com/callback"
    end
  end

  context "with an already verified user" do
    it "shows verified page when no redirectionUri" do
      user = create_user
      user.is_email_address_verified = true
      user.save!

      path = Marten.routes.reverse("verify_email")
      response = Marten::Spec.client.get(
        "#{path}?code=sometoken&user=#{user.hashed_id}"
      )

      response.status.should eq 200
      response.content.should contain("Email address verified")
    end
  end

  context "with an invalid code" do
    it "returns 422" do
      user = create_user
      user.generate_email_verification_token!(nil)
      user.save!

      path = Marten.routes.reverse("verify_email")
      response = Marten::Spec.client.get(
        "#{path}?code=wrongcode&user=#{user.hashed_id}"
      )

      response.status.should eq 422
      JSON.parse(response.content)["error"]["messages"].as_a.first.as_s.should contain("Invalid or expired verification code")
    end
  end

  context "with an expired code" do
    it "returns 422" do
      user = create_user
      past = Time.utc - 3600.seconds
      user.email_verification_token = "abc123"
      user.email_verification_token_created_at = past
      user.email_verification_token_expired_at = past
      user.save!

      path = Marten.routes.reverse("verify_email")
      response = Marten::Spec.client.get(
        "#{path}?code=abc123&user=#{user.hashed_id}"
      )

      response.status.should eq 422
      JSON.parse(response.content)["error"]["messages"].as_a.first.as_s.should contain("Invalid or expired verification code")
    end
  end
end
