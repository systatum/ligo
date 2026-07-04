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

    def self.send_verification_email(
      user : Auth::User,
      token : String,
      redirection_uri : String? = nil,
    ) : EmailDeliveryResult
      base_url = AppSettings.instance.ligo_app_base_url
      confirm_route = "#{base_url}#{Marten.routes.reverse("auth:api_verify_email")}"
      form_route = "#{base_url}#{Marten.routes.reverse("auth:api_verify_email_form")}"

      user_hashed = user.hashed_id

      verify_uri = URI.parse(confirm_route)
      verify_uri.query = URI::Params.encode({
        "code"           => token,
        "user"           => user_hashed,
        "redirectionUri" => redirection_uri || "",
      }.reject { |_, v| v.empty? })
      verification_url = verify_uri.to_s

      form_uri = URI.parse(form_route)
      form_uri.query = URI::Params.encode({
        "user"           => user_hashed,
        "redirectionUri" => redirection_uri || "",
      }.reject { |_, v| v.empty? })
      form_url = form_uri.to_s

      result = nil
      I18n.with_locale(user.locale!) do
        content = MarkdownRenderer.for("auth/emails/email_verification.md").render({
          "verification_url"  => verification_url,
          "verification_code" => token,
          "form_url"          => form_url,
        })

        full_name = "#{user.first_name!} #{user.last_name.to_s}".strip
        subject = I18n.t("emails.email_verification.subject")

        result = Email.deliver_email_content(
          to: [{name: full_name, email: user.email!}],
          subject: subject,
          content: content,
          app_mode: AppSettings.app_mode,
          locale: user.locale!,
        )
      end

      result.not_nil!
    end
  end
end
