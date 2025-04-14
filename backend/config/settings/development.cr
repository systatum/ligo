Marten.configure :development do |config|
  config.debug = true
  config.host = "0.0.0.0"
  config.port = 3000

  # configure the database
  config.database do |db|
    db.host = "ligo_db"
    db.name = "ligo_development"
    db.user = "root"
    db.password = "ligo_db_root_password"
  end
end
