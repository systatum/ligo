module Antrikan::OperatingHourHelper
  @op_hour : OperatingHour?
  @op_hour_schema : OperatingHourSchema?

  private def op_hour
    @op_hour ||= OperatingHour
      .filter_by_hashed_id(params["operating_hour_hashed_id"].to_s)
      .get!(space_id: space.id)
  end

  private def op_hour_schema
    @op_hour_schema ||= OperatingHourSchema.new(request.data)
  end

  private def normalize_duration_params!
    ["open_time", "close_time"].each do |k|
      next unless request.data[k]
      s = extract_param_string?(request.data[k])
      request.data[k] = [Converter.normalize_time_notation(s)] if s
    end
  end

  private def extract_param_string?(val) : String?
    case val
    when String
      val
    when JSON::Any
      val.as_s?
    else
      nil
    end
  end
end
