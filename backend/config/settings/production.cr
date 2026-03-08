require "./concerns/**"

Marten.configure :production do |config|
  DatabaseConfig.configure(config)
  SMTPConfig.configure(config)
  S3Config.configure(config)

  config.host = "0.0.0.0"
  config.port = 8000

  config.allowed_hosts = ["ligo.systatum.com"]
end
