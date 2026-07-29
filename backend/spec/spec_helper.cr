ENV["LIGO_APP_MODE"] ||= "workaty" # default/fallback top-level app mode
ENV["MARTEN_ENV"] = "test"

require "spectator"

require "../src/project"
require "marten/spec"
require "sidekiq/api"
require "./factories/**"
require "../src/lib/**"
require "../src/cli/migrate_system_fields"

class Marten::Core::Storage::FileSystem
  def clear_for_specs!
    FileUtils.rm_rf(@root)
    FileUtils.mkdir_p(@root)
  end
end

class MartenS3::Store
  def clear_for_specs!
    keys = [] of String

    @client.list_objects(@bucket).each do |response|
      response.contents.each do |object|
        keys << object.key
      end
    end

    keys.each_slice(1000) do |slice|
      @client.batch_delete(@bucket, slice)
    end
  end
end

def clear_media_storage_for_specs!
  storage = Marten.media_files_storage

  case storage
  when MartenS3::Store
    storage.clear_for_specs!
  when Marten::Core::Storage::FileSystem
    storage.clear_for_specs!
  end
rescue
  nil
end

def flush_db_for_specs!
  Marten::DB::Connection.registry.values.each do |conn|
    Marten::DB::Management::SchemaEditor.run_for(conn) do |schema_editor|
      schema_editor.flush_model_tables
    end
  end
end

# We define configs for Spectator (a spec framework built on
# top of Crystal's spec) to handle custom behaviours and other things
# that Marten would otherwise handle automatically with Crystal spec
Spectator.configure do |config|
  # This hook should also apply to the default specs because
  # this is also fired once before the entire test run
  config.before_suite do
    SystemFieldsMigrator.migrate!
  end

  # However, this hook is only scoped to Spectator's own spec runner
  # which doesn't have test isolation already set up as Marten did,
  # so we apply our own per-case data flushing here (in the exact same
  # way as Marten v0.6.0).
  config.after_each do
    flush_db_for_specs!
    clear_media_storage_for_specs!
    Sidekiq.redis { |conn| conn.flushdb }
  end
end

Spec.after_each do
  # No need to flush db here as it's already done automatically by Marten
  clear_media_storage_for_specs!
  Sidekiq.redis { |conn| conn.flushdb }
end

def date_time_format
  /\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z/
end

def create_field(name : String, data_type : FieldDataType) : FieldDefinition
  FieldDefinition.new(
    name: name,
    resource_type: FieldResourceType::CANDIDATE,
    data_type: data_type,
    is_system_field: false
  ).tap(&.save!)
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

def capture_redis_messages(channel : String, count : Int, timeout = 2.seconds, &) : Array(String)
  collect_redis_messages(channel, count: count, timeout: timeout) { yield }
end

private def collect_redis_messages_by_channel(
  channels : Array(String), per_channel_count : Int, timeout : Time::Span, &
) : Hash(String, Array(String))
  received = Channel({String, Array(String)}).new(channels.size)
  subscribed = Channel(Nil).new(channels.size)

  channels.each do |channel|
    spawn(name: "test_redis_multi_sub") do
      redis = RedisPool.new_connection
      messages = [] of String
      redis.subscribe(channel) do |on|
        on.subscribe { |_ch, _count| subscribed.send(nil) }
        on.message do |_ch, payload|
          messages << payload
          redis.unsubscribe([] of String) if messages.size >= per_channel_count
        end
      end
      received.send({channel, messages})
    end
  end

  channels.size.times { subscribed.receive }
  yield

  result = Hash(String, Array(String)).new
  channels.size.times do
    select
    when pair = received.receive
      channel, messages = pair
      result[channel] = messages unless messages.empty?
    when timeout(timeout)
    end
  end
  result
end

# Subscribes to several redis channels at once, returning received payloads keyed by
# the channel they arrived on - for asserting a single action fans out to multiple
# channels (e.g. Antrikan's per-channel websocket broadcast for a multi-channel queue).
def capture_redis_messages_by_channel(
  channels : Array(String), per_channel_count : Int = 1, timeout = 2.seconds, &
) : Hash(String, Array(String))
  collect_redis_messages_by_channel(channels, per_channel_count: per_channel_count, timeout: timeout) { yield }
end

def expect_no_redis_message(channel : String, wait = 0.1.seconds, &) : Nil
  collect_redis_messages(channel, count: 1, timeout: wait) { yield }.should be_empty
end
