class Socky::Connection
  getter socket : ::HTTP::WebSocket
  getter user : Ligo::User

  PING_INTERVAL = 30.seconds
  PONG_TIMEOUT  = 45.seconds

  @subscribed_channel_keys = Set(String).new
  @last_pong_at : Time = Time.utc

  def initialize(user : Ligo::User, socket : ::HTTP::WebSocket)
    @user = user
    @socket = socket
  end

  def start
    @socket.on_pong { @last_pong_at = Time.utc }
    @socket.on_message { |raw| handle_message(raw) }
    @socket.on_close { Socky::Hub.disconnect(self) }

    spawn { heartbeat }
  end

  # Bookkeeping for disconnect: we clean it up from all channels
  def remember_subscription(channel_key : String) : Nil
    @subscribed_channel_keys << channel_key
  end

  def forget_subscription(channel_key : String) : Nil
    @subscribed_channel_keys.delete(channel_key)
  end

  def each_subscribed_channel_key(&) : Nil
    @subscribed_channel_keys.each { |channel_key| yield channel_key }
  end

  private def handle_message(raw : String)
    begin
      data = JSON.parse(raw)
      case data["type"]?.try(&.as_s)
      when "subscribe"
        subscribe(data["payload"]["channel_ids"].as_a.map(&.as_s))
      when "unsubscribe"
        unsubscribe(data["payload"]["channel_ids"].as_a.map(&.as_s))
      else
        # not a Socky control message, nothing to dispatch server-side.
        # Domain events only ever flow server -> client, never the reverse
      end
    rescue JSON::ParseException
      # bad frame from the client, drop it, don't crash the fiber
    rescue ex
      # something bad we don't know happens, better now blew up
      Logger.error("Socky::Connection.handle_message error", err: ex)
    end
  end

  private def subscribe(channel_keys : Array(String))
    channel_keys.each do |channel_key|
      next unless Socky::ChannelAuthorizer.can_access?(@user, channel_key)
      Socky::Hub.subscribe(self, channel_key)
    end
  end

  private def unsubscribe(channel_keys : Array(String))
    channel_keys.each { |channel_key| Socky::Hub.unsubscribe(self, channel_key) }
  end

  private def heartbeat
    begin
      loop do
        sleep PING_INTERVAL
        break if @socket.closed?

        @socket.ping

        # Closing here re-enters HTTP::WebSocket#run's error path, which
        # still fires on_close -> Hub.disconnect. No separate cleanup call.
        if Time.utc - @last_pong_at > PONG_TIMEOUT
          @socket.close(::HTTP::WebSocket::CloseCode::AbnormalClosure, "heartbeat timeout")
          break
        end
      end
    rescue IO::Error
      # socket already gone by the time we tried to ping it, on_close (or
      # the rescue in HTTP::WebSocket#run) already handled cleanup.
    end
  end
end
