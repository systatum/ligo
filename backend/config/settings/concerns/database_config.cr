require "dotenv"

Dotenv.load if File.exists?(".env")

module DatabaseConfig
  def self.configure(config)
    config.database do |db|
      db.host = ENV.fetch("LIGO_DB_HOST", AppSettings.instance.ligo_database_host)
      db.name = ENV.fetch("LIGO_DB_NAME", AppSettings.instance.ligo_database_name)
      db.user = ENV.fetch("LIGO_DB_USERNAME", AppSettings.instance.ligo_database_user)
      db.password = ENV.fetch("LIGO_DB_PASSWORD", AppSettings.instance.ligo_database_password)
      db.port = ENV.fetch("LIGO_DB_PORT", AppSettings.instance.ligo_database_port.to_s).to_i
    end
  end
end
