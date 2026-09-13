# This middleware tracks running/complete/failed jobs
class JobStatusTracker < Sidekiq::Middleware::ServerEntry
  def initialize(@expiration : Int32 = Sidekiq::Status.expiration)
  end

  def call(job : Sidekiq::Job, ctx : Sidekiq::Context, &block : -> Bool) : Bool
    Sidekiq::Status.write_field(job.jid, {
      "status"     => "working",
      "job"        => job.klass,
      "started_at" => Time.utc.to_unix.to_s,
      "updated_at" => Time.utc.to_unix.to_s,
    }, @expiration)

    result = yield

    Sidekiq::Status.write_field(job.jid, {
      "status"     => "complete",
      "updated_at" => Time.utc.to_unix.to_s,
      "ended_at"   => Time.utc.to_unix.to_s,
    }, @expiration)
    result
  rescue ex
    Sidekiq::Status.write_field(job.jid, {
      "status"        => "failed",
      "updated_at"    => Time.utc.to_unix.to_s,
      "ended_at"      => Time.utc.to_unix.to_s,
      "error_class"   => ex.class.to_s,
      "error_message" => ex.message || ex.class.to_s,
    }, @expiration)
    raise ex
  end
end

# This middleware marks job as queued on push
class JobQueuedMarker < Sidekiq::Middleware::ClientEntry
  def initialize(@expiration : Int32 = Sidekiq::Status.expiration)
  end

  def call(job : Sidekiq::Job, ctx : Sidekiq::Context, &block : -> Bool) : Bool
    result = yield
    if result
      Sidekiq::Status.write_field(job.jid, {
        "status"      => "queued",
        "job"         => job.klass,
        "enqueued_at" => Time.utc.to_unix.to_s,
        "updated_at"  => Time.utc.to_unix.to_s,
      }, @expiration)
    end
    result
  end
end
