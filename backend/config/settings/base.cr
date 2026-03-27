Marten.configure do |config|
  app_settings = AppSettings.instance

  config.i18n.default_locale = "en-US"
  config.i18n.available_locales = ["en-US"]

  config.auth.user_model = Auth::User

  # IMPORTANT: please ensure that the secret key value is kept secret!
  config.secret_key = "__insecure_a63d0fb74b31bb30bb5eb80d15fb691df300155913e8d4eb4e651310b8803fca__"

  config.method_override.allowed_methods = ["GET", "POST", "DELETE", "PATCH"]
  config.method_override.http_header_name = "X-Http-Method-Override"
  config.method_override.input_name = "_method"

  # Installed applications
  # https://martenframework.com/docs/development/reference/settings#installed_apps
  config.installed_apps = [
    Auth::App,
    Antrikan::App,
    Workaty::App,
    MartenS3::App,
  ] of Marten::Apps::Config.class

  # Application middlewares
  # https://martenframework.com/docs/development/reference/settings#middleware
  config.middleware = [
    CrossRequestAuthorizer,
    OptionsRequestResponder,
    UserDetector,
    Marten::Middleware::Session,
    Marten::Middleware::Flash,
    Marten::Middleware::GZip,
    Marten::Middleware::XFrameOptions,
    MartenAuth::Middleware,
  ]

  # Databases
  # https://martenframework.com/docs/development/reference/settings#database-settings
  config.database do |db| # ameba:disable Naming/BlockParameterName
    db.backend = :mysql
  end

  # Templates context producers
  # https://martenframework.com/docs/development/reference/settings#context_producers
  config.templates.context_producers = [
    Marten::Template::ContextProducer::Request,
    Marten::Template::ContextProducer::Flash,
    Marten::Template::ContextProducer::Debug,
    Marten::Template::ContextProducer::I18n,
  ]

  # configure the mailer
  config.emailing.backend = MartenSMTPEmailing::Backend.new(
    host: app_settings.ligo_mailer_smtp_host,
    port: app_settings.ligo_mailer_smtp_port,
    helo_domain: app_settings.ligo_mailer_smtp_domain,
    use_tls: app_settings.ligo_mailer_smtp_use_starttls,
    username: app_settings.ligo_mailer_smtp_use_auth ? app_settings.ligo_mailer_smtp_username : nil,
    password: app_settings.ligo_mailer_smtp_use_auth ? app_settings.ligo_mailer_smtp_password : nil,
  )

  # configure the file system storage
  config.media_files.storage = MartenS3::Store.new(
    region: app_settings.ligo_s3_region,
    bucket: app_settings.ligo_s3_bucket,
    access_key: app_settings.ligo_s3_access_key,
    secret_key: app_settings.ligo_s3_secret_key,
    endpoint: app_settings.ligo_s3_endpoint.empty? ? nil : app_settings.ligo_s3_endpoint,
    force_path_style: app_settings.ligo_s3_force_path_style,
  )

  # configure Sidekiq client, the redis settings are read from the environment
  Sidekiq::Status.expiration = app_settings.ligo_sidekiq_job_status_expiry
  Sidekiq::Client.default_context = Sidekiq::Client::Context.new(Sidekiq::RedisConfig.new)
  Sidekiq::Client.middleware.add JobQueuedMarker.new
end
