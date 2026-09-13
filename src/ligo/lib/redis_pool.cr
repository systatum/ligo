# Redis for non-Sidekiq callers.
class RedisPool
  @@client : Redis::PooledClient?

  # Shared, fiber-safe pooled connection for short commands like publish.
  # Not for pub/sub, that blocks the connection.
  def self.client : Redis::PooledClient
    @@client ||= Redis::PooledClient.new(
      host: AppSettings.instance.ligo_redis_host,
      port: AppSettings.instance.ligo_redis_port,
      password: AppSettings.instance.ligo_redis_password.presence,
      database: AppSettings.instance.ligo_redis_database_number,
    )
  end

  # Fresh connection for pub/sub subscribers that block on a single connection.
  def self.new_connection : Redis
    s = AppSettings.instance
    Redis.new(
      host: s.ligo_redis_host,
      port: s.ligo_redis_port,
      password: s.ligo_redis_password.presence,
      database: s.ligo_redis_database_number,
    )
  end
end
