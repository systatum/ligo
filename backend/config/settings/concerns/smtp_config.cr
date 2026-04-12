module SMTPConfig
  def self.configure(config)
    settings = AppSettings.instance
    config.emailing.backend = MartenSMTPEmailing::Backend.new(
      host: settings.ligo_mailer_smtp_host,
      port: settings.ligo_mailer_smtp_port,
      helo_domain: settings.ligo_mailer_smtp_domain,
      use_tls: settings.ligo_mailer_smtp_use_starttls,
      username: settings.ligo_mailer_smtp_use_auth ? settings.ligo_mailer_smtp_username : nil,
      password: settings.ligo_mailer_smtp_use_auth ? settings.ligo_mailer_smtp_password : nil,
    )
  end
end
