require "./concerns/**"

Marten.configure :development do |config|
  DatabaseConfig.configure(config)
  SMTPConfig.configure(config)
  S3Config.configure(config)

  config.debug = true
  config.host = "0.0.0.0"
  config.port = 3000
end
