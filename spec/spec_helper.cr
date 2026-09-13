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
    Sidekiq.redis { |conn| conn.flushdb }
  end
end

Spec.after_each do
  # No need to flush db here as it's already done automatically by Marten
  Sidekiq.redis { |conn| conn.flushdb }
end

def create_user(
  email : String = "test-#{Random::Secure.hex(4)}@example.com",
  password : String = "secret123",
) : Ligo::User
  user = Ligo::User.new(
    email: email,
    first_name: "Test",
    last_name: "User",
    password_updated_at: Time.utc
  )
  user.set_password(password)
  user.save!
  user
end

def create_organization(name : String = "Test Organization #{Random.rand(100_000)}") : Ligo::Organization
  Ligo::Organization.create!(name: name)
end

def date_time_format
  /\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z/
end

PNG_1X1 = Base64.decode_string("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==")

def build_http_uploaded_file(
  filename : String = "thumbnail.png",
  content : String = PNG_1X1,
) : Marten::HTTP::UploadedFile
  part = HTTP::FormData::Part.new(
    HTTP::Headers{
      "Content-Disposition" => %(form-data; name="profile_picture"; filename="#{filename}"),
    },
    IO::Memory.new(content)
  )

  Marten::HTTP::UploadedFile.new(part)
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

def expect_jobs(job_class, count = 1, queue = "default", &)
  q = Sidekiq::Queue.new(queue)
  initial_size = q.size
  yield
  final_size = q.size
  (final_size - initial_size).should eq(count)

  jobs = q.to_a.last(count)
  jobs.each do |job|
    job.klass.should eq(job_class.to_s)
  end
end

def expect_no_jobs(job_class, queue = "default", &)
  expect_jobs(job_class, 0, queue: queue) do
    yield
  end
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
