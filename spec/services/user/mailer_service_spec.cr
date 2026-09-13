require "../../spec_helper"

describe Ligo::User::MailerService do
  describe ".send_password_reset_email" do
    it "builds an english password reset email" do
      user = create_user(email: "adam@example.com")

      user.generate_password_reset_token
      user.save!

      result = Ligo::User::MailerService.send_password_reset_email(user)

      result.success.should be_true
      result.email.to.first.address.should eq "adam@example.com"
      result.email.to.first.name.should eq "Test User"
      result.email.subject.should eq I18n.t("emails.password_reset.subject", locale: "en-US")

      html = result.email.context[:content_html].raw.as(String)
      html.should contain("reset")

      intro = I18n.t("emails.password_reset.intro", locale: "en-US")
      instructions = I18n.t("emails.password_reset.instructions", locale: "en-US")
      cta = I18n.t("emails.password_reset.cta", locale: "en-US")
      or_visit = I18n.t("emails.password_reset.or_visit", locale: "en-US")
      notice = I18n.t("emails.password_reset.notice", locale: "en-US")

      html.should contain(intro)
      html.should contain(instructions)
      html.should contain(cta)
      html.should contain(or_visit)
      html.should contain(notice)

      url = "/auth/reset-password/confirm/#{user.hashed_id}/#{user.reset_password_token}"
      html.should contain(url)
    end
  end

  describe ".send_verification_email" do
    it "builds an english email verification email" do
      user = create_user(email: "adam@example.com")

      result = Ligo::User::MailerService.send_verification_email(
        user: user,
        token: "workaty",
        redirection_uri: "https://frontend.com/callback"
      )

      result.success.should be_true
      result.email.to.first.address.should eq "adam@example.com"
      result.email.to.first.name.should eq "Test User"
      result.email.subject.should eq I18n.t("emails.email_verification.subject", locale: "en-US")

      html = result.email.context[:content_html].raw.as(String)
      html.should contain("verify")

      intro = I18n.t("emails.email_verification.intro", locale: "en-US")
      instructions = I18n.t("emails.email_verification.instructions", locale: "en-US")
      cta = I18n.t("emails.email_verification.cta", locale: "en-US")
      code_intro = I18n.t("emails.email_verification.code_intro", locale: "en-US")
      alternative_link = I18n.t("emails.email_verification.alternative_link", locale: "en-US")
      notice = I18n.t("emails.email_verification.notice", locale: "en-US")

      html.should contain(intro)
      html.should contain(instructions)
      html.should contain(cta)
      html.should contain(code_intro)
      html.should contain(alternative_link)
      html.should contain(notice)

      html.should contain("user/verify-email/confirm?code=workaty&amp;user=#{user.hashed_id}&amp;redirectionUri=https%3A%2F%2Ffrontend.com%2Fcallback")
      html.should contain("user/verify-email/form?user=#{user.hashed_id}&amp;redirectionUri=https%3A%2F%2Ffrontend.com%2Fcallback")
    end
  end
end
