ENV["MARTEN_ENV"] = "test"

require "spectator"

require "../src/project"
require "marten/spec"

def flush_db_for_specs!
  Marten::DB::Connection.registry.values.each do |conn|
    Marten::DB::Management::SchemaEditor.run_for(conn) do |schema_editor|
      schema_editor.flush_model_tables
    end
  end
end

Spectator.configure do |config|
  config.after_each do
    flush_db_for_specs!
  end
end

Spec.after_each do
  # No need to flush db here as it's already done automatically by Marten
end

def create_user(email : String = "test-#{Random::Secure.hex(4)}@example.com") : Ligo::User
  user = Ligo::User.new(
    email: email,
    first_name: "Test",
    last_name: "User",
    password_updated_at: Time.utc
  )
  user.set_password("secret123")
  user.save!
  user
end

private def collect_redis_messages(channel : String, count : Int, timeout : Time::Span, &) : Array(String)
  received = Channel(Array(String)).new(1)

  spawn(name: "test_redis_sub") do
    redis = RedisPool.new_connection
    messages = [] of String
    redis.subscribe(channel) do |on|
      on.message do |_ch, payload|
        messages << payload
        redis.unsubscribe([] of String) if messages.size >= count
      end
    end
    received.send(messages)
  end

  sleep(0.05.seconds)
  yield

  select
  when m = received.receive
    m
  when timeout(timeout)
    [] of String
  end
end

def capture_redis_message(channel : String, timeout = 2.seconds, &) : String?
  collect_redis_messages(channel, count: 1, timeout: timeout) { yield }.first?
end

# A minimal IO that captures writes, for verifying WebSocket sends
# without needing a real TCP socket.
class TestIO < IO
  getter buffer : IO::Memory = IO::Memory.new

  def read(slice : Bytes) : Int32
    0
  end

  def write(slice : Bytes) : Nil
    buffer.write(slice)
  end

  def closed? : Bool
    false
  end

  def includes?(str : String) : Bool
    buffer.to_s.includes?(str)
  end
end

def make_socky_connection(user : Ligo::User? = nil) : {Socky::Connection, TestIO}
  user ||= create_user
  io = TestIO.new
  ws = ::HTTP::WebSocket.new(io)
  {Socky::Connection.new(user, ws), io}
end
