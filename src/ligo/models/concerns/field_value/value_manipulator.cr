module FieldValueConcerns::ValueManipulator
  def value
    case field_def.not_nil!.data_type_enum
    when FieldDataType::DTYPE_STRING
      string_value
    when FieldDataType::DTYPE_TEXT
      text_value
    when FieldDataType::DTYPE_INT
      integer_value
    when FieldDataType::DTYPE_FLOAT
      float_value
    when FieldDataType::DTYPE_DATE
      date_value
    when FieldDataType::DTYPE_TIME
      time_value
    when FieldDataType::DTYPE_DATETIME
      datetime_value
    when FieldDataType::DTYPE_BOOLEAN
      boolean_value
    else
      nil
    end
  end

  def actual_value
    string_value ||
      text_value ||
      integer_value ||
      float_value ||
      date_value ||
      time_value ||
      datetime_value ||
      boolean_value
  end

  private def blank_value?(value)
    value.nil? || (value.responds_to?(:empty?) && value.empty?)
  end

  def value=(val)
    clear_all_values

    case field_def.not_nil!.data_type_enum
    when FieldDataType::DTYPE_STRING, FieldDataType::DTYPE_TEXT_RICH
      self.string_value = val.try(&.to_s)
    when FieldDataType::DTYPE_TEXT
      self.text_value = val.try(&.to_s)
    when FieldDataType::DTYPE_INT
      self.integer_value =
        if val.is_a?(Int64)
          val
        elsif val.is_a?(Int32)
          val.to_i64
        else
          val.try(&.to_s).try { |s| s.to_i64? }
        end
    when FieldDataType::DTYPE_FLOAT
      self.float_value =
        if val.is_a?(Float64)
          val
        elsif val.is_a?(Float32)
          val.to_f64
        elsif val.is_a?(Int64) || val.is_a?(Int32)
          val.to_f64
        else
          val.try(&.to_s).try { |s| s.to_f64? }
        end
    when FieldDataType::DTYPE_DATE
      self.date_value =
        if val.is_a?(Time)
          Time.utc(val.year, val.month, val.day)
        else
          val.try(&.to_s).try { |s| Time.parse(s, "%Y-%m-%d", Time::Location::UTC) }
        end
    when FieldDataType::DTYPE_TIME
      self.time_value = val.is_a?(Time) ? val : val.try(&.to_s).try { |s| Time.parse(s, "%H:%M:%S", Time::Location::UTC) }
    when FieldDataType::DTYPE_DATETIME
      self.datetime_value =
        if val.is_a?(Time)
          val
        else
          val.try(&.to_s).try { |s| Time.parse(s, "%Y-%m-%dT%H:%M:%S", Time::Location::UTC) }
        end
    when FieldDataType::DTYPE_BOOLEAN
      self.boolean_value = val.try { |v| v.to_s.downcase.in?(["true", "1", "yes"]) }
    end
  end

  private def clear_all_values
    self.string_value = nil
    self.text_value = nil
    self.integer_value = nil
    self.float_value = nil
    self.date_value = nil
    self.time_value = nil
    self.datetime_value = nil
    self.boolean_value = nil
  end
end
