class FormPayload
  getter native_fields : Hash(String, JSON::Any)
  getter dynamic_fields : Hash(String, JSON::Any)

  def initialize(data)
    parsed = to_json(data)
    fields_data = parsed["fields"]?

    if fields_data && fields_data.as_h?
      fields_hash = fields_data.as_h
      @native_fields = extract_fields_from_json(fields_hash["native"]?)
      @dynamic_fields = extract_fields_from_json(fields_hash["dynamic"]?)
    else
      @native_fields = {} of String => JSON::Any
      @dynamic_fields = {} of String => JSON::Any
    end
  end

  def initialize(data : String)
    parsed = JSON.parse(data)
    fields_data = parsed["fields"]?

    if fields_data && fields_data.as_h?
      fields_hash = fields_data.as_h
      @native_fields = extract_fields_from_json(fields_hash["native"]?)
      @dynamic_fields = extract_fields_from_json(fields_hash["dynamic"]?)
    else
      @native_fields = {} of String => JSON::Any
      @dynamic_fields = {} of String => JSON::Any
    end
  end

  private def to_json(data) : JSON::Any
    io = IO::Memory.new
    data.to_json(io)
    JSON.parse(io.to_s)
  end

  private def extract_fields(value) : Hash(String, JSON::Any)
    return {} of String => JSON::Any unless value

    if value.is_a?(Hash)
      result = {} of String => JSON::Any
      value.each do |k, v|
        result[k.to_s] = coerce(v)
      end
      result
    else
      {} of String => JSON::Any
    end
  end

  private def extract_fields_from_json(value) : Hash(String, JSON::Any)
    return {} of String => JSON::Any unless value

    if value.is_a?(JSON::Any) && value.as_h?
      result = {} of String => JSON::Any
      value.as_h.each do |k, v|
        result[k] = v
      end
      result
    else
      {} of String => JSON::Any
    end
  end

  private def coerce(value) : JSON::Any
    case value
    when JSON::Any
      value
    when String
      JSON::Any.new(value)
    when Int32, Int64
      JSON::Any.new(value.to_i64)
    when Float32, Float64
      JSON::Any.new(value.to_f64)
    when Bool
      JSON::Any.new(value)
    when Nil
      JSON::Any.new(nil)
    else
      JSON::Any.new(value.to_s)
    end
  end
end
