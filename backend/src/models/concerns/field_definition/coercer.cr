module FieldDefinitionConcerns::Coercer
  RESOURCE_TYPE_MAP = FieldResourceType.values.to_h { |v| {v.to_s.upcase, v.value.to_i64} }

  alias FDCMeta = FieldDefinitionConcerns::MetafieldManipulator
  CHOICE_DTYPES = FDCMeta::CHOICE_DTYPES
  FILE_DTYPES   = FDCMeta::FILE_DTYPES

  macro included
    before_validation :coerce_and_normalize!
    validate :validate_normalized_metadata_structure
  end

  def coerce_resource_type!
    rt = @resource_type
    return if rt.nil?

    case rt
    when Int64, Int32
      return
    when String
      s = rt.as(String)

      if (ival = s.to_i64?)
        @resource_type = ival
        return
      end

      upper = s.upcase
      if RESOURCE_TYPE_MAP.has_key?(upper)
        @resource_type = RESOURCE_TYPE_MAP[upper]
        return
      end

      raise ArgumentError.new("Unknown resource_type string: '#{s}'. Valid types: #{RESOURCE_TYPE_MAP.keys.join(", ")}")
    else
      raise TypeCastError.new("resource_type must be Int64, Int32, or String, got: #{rt.class}")
    end
  end

  def normalize_metadata!
    return if @metadata.nil?

    begin
      normalized = FieldDefinitionConcerns::MetafieldManipulator.normalize_for(data_type, @metadata)
    rescue ex : Exception
      raise ex
    end

    if normalized
      @metadata = JSON.parse(normalized.to_json)
      return
    end

    if choice_type? || file_type?
      return
    else
      @metadata = nil
    end
  end

  def coerce_and_normalize!
    coerce_resource_type!
    normalize_metadata!
  end

  def choice_type? : Bool
    return false if data_type.nil?
    CHOICE_DTYPES.includes?(data_type.not_nil!)
  end

  def file_type? : Bool
    return false if data_type.nil?
    FILE_DTYPES.includes?(data_type.not_nil!)
  end

  def need_metadata? : Bool
    choice_type? || file_type?
  end

  def humanized_data_type : String
    if CHOICE_DTYPES.includes?(data_type.not_nil!)
      "choice field"
    elsif FILE_DTYPES.includes?(data_type.not_nil!)
      "file field"
    else
      raise "Unknown data type: #{data_type.not_nil!}"
    end
  end

  private def validate_normalized_metadata_structure
    return if data_type.nil?

    if need_metadata?
      if @metadata.nil?
        errors.add(:metadata, "is required for #{humanized_data_type}")
      else
        normalized = FieldDefinitionConcerns::MetafieldManipulator.normalize_for(data_type, @metadata)
        unless normalized
          errors.add(:metadata, "invalid metadata structure for #{humanized_data_type}")
        end
      end
    else
      errors.add(:metadata, "not needed for #{humanized_data_type}") if @metadata
    end
  end
end
