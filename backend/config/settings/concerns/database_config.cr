module DatabaseConfig
  def self.configure(config)
    config.database do |db|
      db.host = AppSettings.instance.ligo_database_host
      db.name = AppSettings.instance.ligo_database_name
      db.user = AppSettings.instance.ligo_database_user
      db.password = AppSettings.instance.ligo_database_password
      db.port = AppSettings.instance.ligo_database_port
    end
  end
end
