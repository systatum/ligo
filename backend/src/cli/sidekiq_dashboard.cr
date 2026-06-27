require "../project"
require "random/secure"
require "sidekiq/web"

SidekiqConfig.configure
Sidekiq::Client.default_context = Sidekiq::Client::Context.new(Sidekiq::RedisConfig.new)

Kemal::Session.config do |config|
  config.secret = SidekiqConfig.dashboard_session_secret || Random::Secure.hex(64)
end

Kemal.config do |config|
  config.add_handler CSRF.new
end

Kemal.run
