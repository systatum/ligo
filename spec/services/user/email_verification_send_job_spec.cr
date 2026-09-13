require "../../spec_helper"

describe Ligo::User::EmailVerificationSendJob do
  context "when user is found" do
    it "generates a verification token, saves the user, and sends a verification email" do
      user = create_user(email: "test@example.com")
      user.email_verification_token.should be_nil
      user.email_verification_token_created_at.should be_nil

      result = Ligo::User::EmailVerificationSendJob.new.perform(user.email!, nil, nil)

      result.should be_a EmailDeliveryResult
      result.not_nil!.success.should be_true

      Marten::Spec.delivered_emails.size.should eq 1
      Marten::Spec.delivered_emails[0].subject.should eq I18n.t("emails.email_verification.subject", locale: "en-US")

      user.reload
      user.email_verification_token.should_not be_nil
      user.email_verification_token.not_nil!.size.should eq 6
      user.email_verification_token_created_at.should_not be_nil
    end
  end

  context "when user is not found" do
    it "returns nil silently" do
      result = Ligo::User::EmailVerificationSendJob.new.perform("nonexistent@example.com", nil, nil)
      result.should be_nil
    end
  end

  context "when user email is already verified" do
    it "returns nil silently" do
      user = create_user(email: "verified@example.com")
      user.is_email_address_verified = true
      user.save!

      result = Ligo::User::EmailVerificationSendJob.new.perform(user.email!, nil, nil)
      result.should be_nil
    end
  end
end
