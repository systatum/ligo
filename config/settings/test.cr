Marten.configure :test do |config|
  config.database do |db|
    db.host = "127.0.0.1"
    db.port = 3367
    db.name = "ligo_test"
    db.user = "devroot"
    db.password = "devroot"
  end

  # Collect sent emails to inspect in specs instead of hitting real SMTP.
  config.emailing.backend = Marten::Emailing::Backend::Development.new(collect_emails: true, print_emails: false)
end
