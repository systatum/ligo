Marten.configure :development do |config|
  config.database do |db|
    db.host = "127.0.0.1"
    db.port = 3367
    db.name = "ligo_development"
    db.user = "devroot"
    db.password = "devroot"
  end
end
