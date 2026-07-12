module Socky::Broadcaster
  CHANNEL_PATTERN = "socky:channel:*"

  # Public API domain code calls. We don't track "who's connected on which
  # instance" anywhere. Publish, and whichever process actually holds a
  # subscribed connection delivers it locally. Every other process's
  # subscriber finds nothing local for this channel_key and no-ops
  def self.publish(channel_key : String, payload_json : String) : Nil
    begin
      RedisPool.client.publish("socky:channel:#{channel_key}", payload_json)
    rescue ex
      Logger.error("Socky::Broadcaster.publish failed for #{channel_key}", err: ex)
    end
  end

  # Call once, in its own fiber, at boot. One call per app instance
  def self.start_subscriber : Nil
    spawn do
      loop do
        begin
          RedisPool.new_connection.psubscribe(CHANNEL_PATTERN) do |on|
            on.pmessage do |_pattern, channel, message|
              channel_key = channel.split(":", 3).last
              Socky::Hub.deliver_locally(channel_key, message)
            end
          end
        rescue ex
          Logger.error("Socky::Broadcaster subscriber error, reconnecting in 5s", err: ex)
          sleep(5.seconds)
        end
      end
    end
  end
end
