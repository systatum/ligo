Marten.configure do |config|
  app_settings = AppSettings.instance

  config.secret_key = "__insecure_dev_secret_key_for_ligo_core__"

  config.i18n.default_locale = "en-US"
  config.i18n.available_locales = ["en-US", "id-ID", "ja-JP"]
  config.i18n.fallbacks = ["en-US"]

  config.auth.user_model = Ligo::User

  config.installed_apps = [
    Ligo::App,
  ] of Marten::Apps::Config.class

  config.middleware = [
    CrossRequestAuthorizer,
    OptionsRequestResponder,
    UserDetector,
    Marten::Middleware::GZip,
  ]

  config.database do |db|
    db.backend = :mysql
  end

  config.emailing.backend = MartenSMTPEmailing::Backend.new(
    host: app_settings.ligo_mailer_smtp_host,
    port: app_settings.ligo_mailer_smtp_port,
    helo_domain: app_settings.ligo_mailer_smtp_domain,
    use_tls: app_settings.ligo_mailer_smtp_use_starttls,
    username: app_settings.ligo_mailer_smtp_use_auth ? app_settings.ligo_mailer_smtp_username : nil,
    password: app_settings.ligo_mailer_smtp_use_auth ? app_settings.ligo_mailer_smtp_password : nil,
  )

  SidekiqConfig.configure
end
