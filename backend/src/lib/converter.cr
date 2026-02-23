module Converter
  # Accepts string formatted as NN:NN from the given value and returns
  # string formatted as NN:NN:NN or raise an error otherwise.
  #
  # This is useful because we (may) want to interpret minutes:seconds
  # as hours:minutes in the codebase.
  def self.normalize_time_notation(value : String) : String
    v = value.strip
    # Match hours (1-2 digits) and minutes (00-59)
    if v.matches?(/^\d{1,2}:[0-5]\d$/)
      return "#{v}:00"
    end
    raise ArgumentError.new("invalid time format: #{value}")
  end

  def self.serialize_time_span(value)
    return nil unless value
    span = value.as(Time::Span)
    "#{span.hours.to_s.rjust(2, '0')}:#{span.minutes.to_s.rjust(2, '0')}"
  end
end
