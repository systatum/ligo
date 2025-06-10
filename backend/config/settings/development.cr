Marten.configure :development do |config|
  config.debug = true
  config.host = "0.0.0.0"
  config.port = 3000

  # configure the database
  config.database do |db|
    db.host = "127.0.0.1"
    db.name = "ligo_development"
    db.user = "root"
    db.password = "ligo_db_root_password"
    db.port = 3366
  end
end
