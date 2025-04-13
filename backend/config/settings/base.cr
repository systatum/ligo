Marten.configure do |config|
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
    Workaty::App,
  ] of Marten::Apps::Config.class

  # Application middlewares
  # https://martenframework.com/docs/development/reference/settings#middleware
  config.middleware = [
    CrossRequestAuthorizer,
    OptionsRequestResponder,
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
end
