module Antrikan
  class OperatingHourSerializer < ModelSerializer
    protected def fields
      record = @record.as(OperatingHour)

      {
        id:         record.hashed_id,
        day:        record.day,
        open_time:  serialize_time_span(record.open_time),
        close_time: serialize_time_span(record.close_time),
      }
    end
  end
end
