# Parses and structures form data from JSON payloads
# containing both native (predefined) and dynamic
# (custom) fields. Expects data in the format:
# `{"fields": {"native": {...}, "dynamic": {...}}}`
class FormPayload
  getter native_fields : Hash(String, JSON::Any)
  getter dynamic_fields : Hash(String, JSON::Any)

  alias AnyFieldType = Array(String) | Marten::Schema::Field::Any | Nil | Marten::HTTP::UploadedFile | Marten::Routing::Parameter::Types

  def initialize(data : JSON::Any)
    fields_data = data["fields"]?

    if fields_data && fields_data.as_h?
      fields_hash = fields_data.as_h
      @native_fields = extract_fields_from_json(fields_hash["native"]?)
      @dynamic_fields = extract_fields_from_json(fields_hash["dynamic"]?)
    else
      @native_fields = {} of String => JSON::Any
      @dynamic_fields = {} of String => JSON::Any
    end
  end

  def initialize(data : Hash)
    fields_data = data["fields"]? || data[:fields]?

    if fields_data.is_a?(Hash)
      @native_fields = extract_fields(fields_data["native"]? || fields_data[:native]?)
      @dynamic_fields = extract_fields(fields_data["dynamic"]? || fields_data[:dynamic]?)
    else
      @native_fields = {} of String => JSON::Any
      @dynamic_fields = {} of String => JSON::Any
    end
  end

  # Accepts Marten request data
  def initialize(data : Marten::HTTP::Params::Data)
    initialize(data.to_h)
  end

  # Accepts JSON string
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

  # Returns *native_fields* as a hash suitable for schema validation.
  def to_validate
    params = {} of String => AnyFieldType

    native_fields.each do |k, v|
      params[k.to_s] = coerce_to_schema_field(v)
    end

    params
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

  private def coerce_to_schema_field(value : JSON::Any) : AnyFieldType
    if value.as_s?
      value.as_s
    elsif value.as_i?
      value.as_i64
    elsif value.as_f?
      value.as_f
    elsif value.as_bool?
      value.as_bool
    else
      nil
    end
  end
end
