require "../../spec_helper"

describe Ligo::User::PasswordResetInitiateJob do
  context "when user is found" do
    it "generates a reset token, saves the user, and sends a password reset email" do
      user = create_user(email: "test@example.com")
      user.reset_password_token.should be_nil
      user.reset_password_token_created_at.should be_nil

      result = Ligo::User::PasswordResetInitiateJob.new.perform(user.email!)

      result.should be_a EmailDeliveryResult
      result.not_nil!.success.should be_true

      Marten::Spec.delivered_emails.size.should eq 1
      Marten::Spec.delivered_emails[0].subject.should eq I18n.t("emails.password_reset.subject", locale: "en-US")

      user.reload
      user.reset_password_token.should_not be_nil
      user.reset_password_token.not_nil!.size.should eq 255
      user.reset_password_token_created_at.should_not be_nil
    end
  end

  context "when user is not found" do
    it "returns nil" do
      result = Ligo::User::PasswordResetInitiateJob.new.perform("non-existent@user.com")
      result.should be_nil
    end
  end
end
