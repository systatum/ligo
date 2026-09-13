Marten.configure :test do |config|
  config.database do |db|
    db.host = "127.0.0.1"
    db.port = 3367
    db.name = "ligo_test"
    db.user = "devroot"
    db.password = "devroot"
  end
end
