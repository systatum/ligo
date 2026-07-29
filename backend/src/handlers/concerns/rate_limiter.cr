module RateLimiter
  private def rate_limit(
    name : String,
    bucket_capacity : Int32 = 3,
    leak_rate : Float32 = 0.1,
    block_for : Int32 = 10,
    &block : Array(String) -> Nil
  )
    keys = [IPDetector.client_ip(request)] of String
    block.call(keys)

    throttle = Prorate::Throttle.new(
      name: name,
      bucket_capacity: bucket_capacity,
      leak_rate: leak_rate,
      block_for: block_for,
      redis: RedisPool.client,
    )
    keys.each { |id| throttle << id }
    throttle.throttle!
  end

  private def rate_limit(
    name : String,
    bucket_capacity : Int32 = 3,
    leak_rate : Float32 = 0.1,
    block_for : Int32 = 10,
  )
    rate_limit(
      name: name,
      bucket_capacity: bucket_capacity,
      leak_rate: leak_rate,
      block_for: block_for
    ) { }
  end
end
