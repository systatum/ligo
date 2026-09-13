module Sidekiq::Status
  KEY_PREFIX = "job:status"

  @@expiration : Int32 = 86_400 # Default 24 hours

  def self.expiration : Int32
    @@expiration
  end

  def self.expiration=(value : Int32)
    @@expiration = value
  end

  # Current status as a string, or nil if expired/unknown
  def self.status(job_id : String) : String?
    get(job_id, "status")
  end

  def self.queued?(job_id : String) : Bool
    status(job_id) == "queued"
  end

  def self.working?(job_id : String) : Bool
    status(job_id) == "working"
  end

  def self.complete?(job_id : String) : Bool
    status(job_id) == "complete"
  end

  def self.failed?(job_id : String) : Bool
    status(job_id) == "failed"
  end

  def self.at(job_id : String) : String?
    get(job_id, "at")
  end

  def self.total(job_id : String) : String?
    get(job_id, "total")
  end

  def self.pct_complete(job_id : String) : String?
    get(job_id, "pct_complete")
  end

  def self.message(job_id : String) : String?
    get(job_id, "message")
  end

  def self.get(job_id : String, field : String) : String?
    val = Sidekiq.redis { |conn| conn.hget(redis_key(job_id), field) }
    val.is_a?(String) ? val : nil
  end

  def self.get_all(job_id : String) : Hash(String, String)?
    result = Sidekiq.redis { |conn| conn.hgetall(redis_key(job_id)) }
    hash = result.as(Hash(String, String))
    hash.empty? ? nil : hash
  end

  def self.fetch(job_id : String) : String?
    data = get_all(job_id)
    return nil unless data
    build_json(job_id, data)
  end

  def self.delete(job_id : String)
    Sidekiq.redis { |conn| conn.del(redis_key(job_id)) }
  end

  # Write fields to the job's Redis hash and reset expiry
  def self.write_field(job_id : String, data : Hash(String, String), expiration : Int32 = @@expiration)
    key = redis_key(job_id)
    Sidekiq.redis do |conn|
      conn.multi do |multi|
        multi.hset(key, data)
        multi.expire(key, expiration)
      end
    end
  end

  private def self.redis_key(job_id : String) : String
    "#{KEY_PREFIX}:#{job_id}"
  end

  private def self.build_json(job_id : String, data : Hash(String, String)) : String
    status = data["status"]?
    Jbuilder.new do |json|
      json.id job_id
      json.status status
      json.error data["error_message"]? if data["error_message"]?
      json.job data["job"]? if data["job"]?
      json.at data["at"]?.try(&.to_i) if data["at"]?
      json.total data["total"]?.try(&.to_i) if data["total"]?
      json.pct_complete data["pct_complete"]?.try(&.to_i) if data["pct_complete"]?
      json.message data["message"]? if data["message"]?
      json.enqueued_at data["enqueued_at"]?.try(&.to_i64) if data["enqueued_at"]?
      json.started_at data["started_at"]?.try(&.to_i64) if data["started_at"]?
      json.updated_at data["updated_at"]?.try(&.to_i64) if data["updated_at"]?
      json.ended_at data["ended_at"]?.try(&.to_i64) if data["ended_at"]?
    end.to_json
  end
end
