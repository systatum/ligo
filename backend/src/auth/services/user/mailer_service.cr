module Auth
  class User::MailerService
    def self.send_password_reset_email(
      user : Auth::User,
      app_mode : String,
    ) : EmailDeliveryResult
      I18n.with_locale(user.locale!) do
        content = MarkdownRenderer.for("auth/emails/password_reset.md").render({
          "hashed_id" => user.hashed_id,
          "token"     => user.reset_password_token,
          "base_url"  => AppSettings.instance.ligo_app_base_url,
        })

        full_name = "#{user.first_name!} #{user.last_name.to_s}".strip

        Email.deliver_email_content(
          to: [{name: full_name, email: user.email!}],
          subject: I18n.t("emails.password_reset.subject"),
          content: content,
          app_mode: app_mode,
          locale: user.locale!,
        )
      end
    end
  end
end
