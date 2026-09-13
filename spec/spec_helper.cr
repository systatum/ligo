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

def create_realm(
  ack_semantic : AcknowledgeSemantic = AcknowledgeSemantic::NONE,
  app_name : String = "TestApp",
  app_id : String = "fb_test_id",
  app_secret : String = "fb_test_secret",
  registration_redirection_uri : String = "https://testapp.example.com/auth/callback",
  registration_ack_uri : String = "https://testapp.example.com/webhooks/iam",
  max_ack_retry_attempts : Int32? = nil,
  default_role : Int32 = Role::OWNER,
  api_secret_key : String = "sk_test_raw_#{Random.rand}",
  api_client_key : String = "ck_test_raw_#{Random.rand}",
) : Ligo::Realm
  realm = Ligo::Realm.new
  realm.id = "test#{Random.rand(10_000..99_999)}"
  realm.app_name = app_name
  realm.hashed_api_secret_key = Digest::SHA256.hexdigest(api_secret_key)
  realm.hashed_api_client_key = Digest::SHA256.hexdigest(api_client_key)
  realm.webhook_secret = Random::Secure.urlsafe_base64(11)
  realm.ack_semantic = ack_semantic
  realm.app_id = app_id
  realm.app_secret = app_secret
  realm.registration_redirection_uri = registration_redirection_uri
  realm.registration_ack_uri = registration_ack_uri
  realm.max_ack_retry_attempts = max_ack_retry_attempts
  realm.default_role = default_role
  realm.save!

  realm
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
