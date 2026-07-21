require "../project"
require "sidekiq/cli"

Marten.setup

SidekiqConfig.configure

cli = Sidekiq::CLI.new
server = cli.configure do |config|
  config.redis = Sidekiq::RedisConfig.new
  config.server_middleware.add PerformerContextRestorer.new
  config.server_middleware.add JobStatusTracker.new
end

cli.run(server)
