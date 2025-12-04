require "json"

module FieldDefinitionConcerns::MetafieldManipulator
  extend self

  CHOICE_DTYPES = [
    FieldDataType::DTYPE_CHOICE_DROPDOWN,
    FieldDataType::DTYPE_CHOICE_RADIO,
    FieldDataType::DTYPE_CHOICE_CHECKBOX,
    FieldDataType::DTYPE_CHOICE_TOGGLE,
  ]

  FILE_DTYPES = [
    FieldDataType::DTYPE_FILE_ANY,
    FieldDataType::DTYPE_FILE_IMAGE,
  ]

  def option(id : String, caption)
    {"id" => id, "caption" => JSON.parse(caption.to_json)}
  end

  def options_meta(options, default : String? = nil) : JSON::Any
    unless options.is_a?(Array) && !options.empty?
      raise ArgumentError.new("options must be a non-empty array")
    end

    normalized_options = [] of Hash(String, JSON::Any)

    options.each_with_index do |raw, idx|
      opt_hash_raw = nil
      if raw.is_a?(Hash)
        opt_hash_raw = raw
      elsif raw.is_a?(JSON::Any) && raw.as_h?
        opt_hash_raw = raw.as_h
      else
        if raw.is_a?(String)
          parsed = begin JSON.parse(raw) rescue nil end
          opt_hash_raw = parsed if parsed.is_a?(Hash)
        end
      end

      unless opt_hash_raw.is_a?(Hash)
        raise ArgumentError.new("option at index #{idx} must be an object with at least an 'id' key")
      end

      unless opt_hash_raw.has_key?("id") && opt_hash_raw["id"].is_a?(String)
        raise ArgumentError.new("option at index #{idx} must include an 'id' string")
      end

      cap_raw = opt_hash_raw["caption"] rescue nil
      if cap_raw.nil?
        raise ArgumentError.new("option at index #{idx} must include a 'caption' value (string or object with 'en')")
      end

      if cap_raw.is_a?(Hash)
        unless cap_raw.has_key?("en") && cap_raw["en"].is_a?(String)
          raise ArgumentError.new("option caption at index #{idx} must include an 'en' locale string")
        end
      elsif cap_raw.is_a?(String)
        # allowed: treat as english caption
      elsif cap_raw.is_a?(JSON::Any)
        if cap_raw.as_h?
          hcap = cap_raw.as_h
          if !hcap.has_key?("en")
            raise ArgumentError.new("option caption at index #{idx} must include an 'en' locale string")
          end
          en_val = hcap["en"]
          if en_val.is_a?(String)
            # ok
          elsif en_val.is_a?(JSON::Any) && en_val.as_s?
            # JSON::Any wrapping a string -> ok
          else
            raise ArgumentError.new("option caption at index #{idx} must include an 'en' locale string")
          end
        elsif cap_raw.as_s?
          # stringified JSON or plain string: accept
        else
          raise ArgumentError.new("option caption at index #{idx} must be a String or an object with locale keys")
        end
      else
        raise ArgumentError.new("option caption at index #{idx} must be a String or an object with locale keys")
      end

      coerced = Hash(String, JSON::Any).new
      opt_hash_raw.each do |k, v|
        coerced[k.to_s] = parse_value_to_json_any(v)
      end

      normalized_options << coerced
    end

    ids = normalized_options.map { |o| o["id"].to_s }
    if ids.size != ids.uniq.size
      raise ArgumentError.new("option ids must be unique")
    end

    if default
      unless ids.includes?(default)
        raise ArgumentError.new("default '#{default}' not found among provided options")
      end
    end

    meta = Hash(String, JSON::Any).new
    meta["options"] = JSON.parse(normalized_options.to_json)
    meta["default"] = JSON.parse(default.to_json) if default
    JSON.parse(meta.to_json)
  end

  def file_meta(many : Bool = false, max_mb : Float64 = 3.0, ok_mimes : String = "*") : JSON::Any
    if max_mb <= 0.0
      raise ArgumentError.new("max_mb must be positive")
    end
    if max_mb > 1024.0
      raise ArgumentError.new("max_mb is unreasonably large")
    end

    k = ok_mimes.to_s.strip
    ok_mimes_str =
      if k.empty?
        "*"
      elsif k == "*"
        "*"
      else
        parts = k.split(",").map { |p| p.to_s.strip }.select { |p| !p.empty? }
        if parts.empty?
          "*"
        else
          parts.each do |s|
            unless s.includes?("/")
              raise ArgumentError.new("invalid mime type: #{s}")
            end
          end
          parts.uniq.join(",")
        end
      end

    meta = Hash(String, JSON::Any).new
    meta["many"] = JSON.parse(many.to_json)
    meta["max_mb"] = JSON.parse(max_mb.to_json)
    meta["ok_mimes"] = JSON.parse(ok_mimes_str.to_json)
    JSON.parse(meta.to_json)
  end

  def parse_json_value_to_float!(val : JSON::Any) : Float64
    if val.as_i?
      val.as_i.to_f
    elsif val.as_f?
      val.as_f
    elsif val.as_s?
      begin
        val.as_s.to_f
      rescue
        raise ArgumentError.new("Cannot convert '#{val.as_s}' to Float64")
      end
    else
      raise ArgumentError.new("Cannot convert JSON::Any of type #{val.raw.class} to Float64")
    end
  end

  def normalize_for(dt : FieldDataType?, meta : JSON::Any?) : Hash(String, JSON::Any)?
    return nil if dt.nil?
    return nil if meta.nil?

    if CHOICE_DTYPES.includes?(dt)
      normalize_choice_type(meta)
    elsif FILE_DTYPES.includes?(dt)
      normalize_file_type(meta)
    else
      nil
    end
  end

  def normalize_choice_type(meta : JSON::Any?) : Hash(String, JSON::Any)?
    return nil if meta.nil?

    h =
      if meta.is_a?(Hash)
        meta
      elsif meta.is_a?(JSON::Any) && meta.as_h?
        meta.as_h
      else
        return nil
      end

    return nil unless h.has_key?("options")

    raw_opts = h["options"]
    arr_opts =
      if raw_opts.is_a?(Array)
        raw_opts
      elsif raw_opts.is_a?(JSON::Any) && raw_opts.as_a?
        raw_opts.as_a
      else
        return nil
      end

    ids = arr_opts.map do |o|
      oh =
        if o.is_a?(Hash)
          o
        elsif o.is_a?(JSON::Any) && o.as_h?
          o.as_h
        else
          nil
        end
      oh && oh.has_key?("id") ? oh["id"].to_s : nil
    end.compact
    return nil if ids.size != arr_opts.size

    arr_opts.each do |o|
      oh =
        if o.is_a?(Hash)
          o
        elsif o.is_a?(JSON::Any) && o.as_h?
          o.as_h
        else
          nil
        end
      cap = oh ? (oh["caption"] rescue nil) : nil
      return nil if cap.nil?

      if cap.is_a?(Hash)
        return nil unless cap.has_key?("en") && cap["en"].is_a?(String)
      elsif cap.is_a?(String)
        # ok
      elsif cap.is_a?(JSON::Any)
        if cap.as_h?
          hh = cap.as_h
          unless hh.has_key?("en")
            return nil
          end
          en_val = hh["en"]
          if en_val.is_a?(String)
            # ok
          elsif en_val.is_a?(JSON::Any) && en_val.as_s?
            # ok
          else
            return nil
          end
        elsif cap.as_s?
          # ok string-like
        else
          return nil
        end
      else
        return nil
      end
    end

    if h.has_key?("default")
      default_val = h["default"].to_s
      return nil unless ids.includes?(default_val)
    end

    result = Hash(String, JSON::Any).new
    result["options"] = JSON.parse(arr_opts.to_json)
    result["default"] = h["default"] if h.has_key?("default")
    result
  end

  def normalize_file_type(meta : JSON::Any?) : Hash(String, JSON::Any)?
    return nil if meta.nil?

    h =
      if meta.is_a?(Hash)
        meta
      elsif meta.is_a?(JSON::Any) && meta.as_h?
        meta.as_h
      else
        return nil
      end

    many =
      if h.has_key?("many")
        raw = h["many"]
        if raw.is_a?(JSON::Any)
          if raw.as_bool?
            raw.as_bool
          elsif raw.as_i?
            raw.as_i != 0
          elsif raw.as_s?
            s = raw.as_s.downcase
            s == "true" || s == "1"
          else
            false
          end
        elsif raw.is_a?(Bool)
          raw
        else
          raw.to_s.downcase == "true"
        end
      else
        false
      end

    max_mb =
      if h.has_key?("max_mb")
        raw = h["max_mb"]
        if raw.is_a?(JSON::Any)
          begin
            parse_json_value_to_float!(raw)
          rescue
            3.0
          end
        elsif raw.is_a?(Int32) || raw.is_a?(Int64) || raw.is_a?(Int)
          raw.to_f
        elsif raw.is_a?(Float32) || raw.is_a?(Float64)
          raw.to_f
        else
          begin
            raw.to_s.to_f
          rescue
            3.0
          end
        end
      else
        3.0
      end

    return nil if max_mb <= 0.0 || max_mb > 1024.0

    ok_mimes_val =
      if h.has_key?("ok_mimes")
        ot = h["ok_mimes"]
        # Only accept string forms for ok_mimes (either String or JSON::Any wrapping a string).
        if ot.is_a?(String)
          s = ot.strip
          if s.empty?
            "*"
          elsif s == "*"
            "*"
          else
            parts = s.split(",").map { |p| p.to_s.strip }.select { |p| !p.empty? }
            return nil if parts.empty?
            return nil if parts.any? { |p| !p.includes?("/") }
            parts.uniq.join(",")
          end
        elsif ot.is_a?(JSON::Any) && ot.as_s?
          s = ot.as_s.strip
          if s.empty?
            "*"
          elsif s == "*"
            "*"
          else
            parts = s.split(",").map { |p| p.to_s.strip }.select { |p| !p.empty? }
            return nil if parts.empty?
            return nil if parts.any? { |p| !p.includes?("/") }
            parts.uniq.join(",")
          end
        else
          # Reject arrays and other non-string forms for ok_mimes
          return nil
        end
      else
        "*"
      end

    result = Hash(String, JSON::Any).new
    result["many"] = JSON.parse(many.to_json)
    result["max_mb"] = JSON.parse(max_mb.to_json)
    result["ok_mimes"] = JSON.parse(ok_mimes_val.to_json)
    result
  end

  private def parse_value_to_json_any(val)
    return val if val.is_a?(JSON::Any)
    begin
      JSON.parse(val.to_json)
    rescue
      begin
        JSON.parse(val.to_s)
      rescue
        begin
          JSON.parse(val.to_s.to_json)
        rescue
          JSON.parse("null")
        end
      end
    end
  end
end
