Marten.configure do |config|
  config.secret_key = "__insecure_dev_secret_key_for_ligo_core__"

  config.installed_apps = [
    Ligo::App,
  ] of Marten::Apps::Config.class

  config.database do |db|
    db.backend = :mysql
  end
end
