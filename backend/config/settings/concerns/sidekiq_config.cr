module SidekiqConfig
  def self.configure
    settings = AppSettings.instance

    redis_host = settings.ligo_sidekiq_redis_host
    redis_port = settings.ligo_sidekiq_redis_port
    redis_database_number = settings.ligo_sidekiq_redis_database_number
    redis_password = settings.ligo_sidekiq_redis_password

    ENV["REDIS_PROVIDER"] ||= "REDIS_URL"
    ENV["REDIS_URL"] ||= build_redis_url(
      redis_host,
      redis_port,
      redis_database_number,
      redis_password
    )

    Sidekiq::Status.expiration = settings.ligo_sidekiq_job_status_expiry

    # configure the client, the redis settings are read from the environment
    Sidekiq::Client.default_context = Sidekiq::Client::Context.new(Sidekiq::RedisConfig.new)
    Sidekiq::Client.middleware.add JobQueuedMarker.new
    Sidekiq::Client.middleware.add PerformerContextPropagator.new
  end

  def self.dashboard_session_secret
    secret = AppSettings.instance.ligo_sidekiq_dashboard_session_secret
    return secret unless secret.empty?
    ENV["SIDEKIQ_DASHBOARD_SESSION_SECRET"]?
  end

  private def self.build_redis_url(
    redis_host : String,
    redis_port : Int32,
    redis_database_number : Int32,
    redis_password : String,
  ) : String
    credentials = redis_password.empty? ? "" : ":#{redis_password}@"
    "redis://#{credentials}#{redis_host}:#{redis_port}/#{redis_database_number}"
  end
end
