require "dotenv"

Dotenv.load if File.exists?(".env")

module SMTPConfig
  def self.configure(config)
    config.emailing.backend = MartenSMTPEmailing::Backend.new(
      host: ENV.fetch(
        "LIGO_MAILER_SMTP_HOST",
        AppSettings.instance.ligo_mailer_smtp_host
      ),
      port: ENV.fetch(
        "LIGO_MAILER_SMTP_PORT",
        AppSettings.instance.ligo_mailer_smtp_port.to_s
      ).to_i,
      helo_domain: ENV.fetch(
        "LIGO_MAILER_SMTP_DOMAIN",
        AppSettings.instance.ligo_mailer_smtp_domain
      ),
      use_tls: ENV.fetch(
        "LIGO_MAILER_SMTP_USE_STARTTLS",
        AppSettings.instance.ligo_mailer_smtp_use_starttls.to_s
      ) == "true",
      username: AppSettings.instance.ligo_mailer_smtp_use_auth ? ENV.fetch(
        "LIGO_MAILER_SMTP_USERNAME",
        AppSettings.instance.ligo_mailer_smtp_username
      ) : nil,
      password: AppSettings.instance.ligo_mailer_smtp_use_auth ? ENV.fetch(
        "LIGO_MAILER_SMTP_PASSWORD",
        AppSettings.instance.ligo_mailer_smtp_password
      ) : nil,
    )
  end
end
