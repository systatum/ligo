module FieldDefinitionConcerns::Coercer
  include FieldEnumCoercer

  alias FDCMeta = FieldDefinitionConcerns::MetafieldManipulator
  CHOICE_DTYPES = FDCMeta::CHOICE_DTYPES
  FILE_DTYPES   = FDCMeta::FILE_DTYPES

  field_enum_coercer :resource_type, FieldResourceType
  field_enum_coercer :data_type, FieldDataType

  def normalize_metadata!
    return if @metadata.nil?

    begin
      normalized = FieldDefinitionConcerns::MetafieldManipulator.normalize_for(data_type_enum, @metadata)
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
    coerce_data_type!
    normalize_metadata!
  end

  def choice_type? : Bool
    return false if data_type.nil?
    CHOICE_DTYPES.includes?(data_type_enum)
  end

  def file_type? : Bool
    return false if data_type.nil?
    FILE_DTYPES.includes?(data_type_enum)
  end

  def need_metadata? : Bool
    choice_type? || file_type?
  end

  def humanized_data_type : String
    dt_enum = data_type_enum
    if CHOICE_DTYPES.includes?(dt_enum)
      "choice field"
    elsif FILE_DTYPES.includes?(dt_enum)
      "file field"
    else
      raise "Unknown data type: #{dt_enum}"
    end
  end

  private def validate_normalized_metadata_structure
    return if data_type.nil?

    if need_metadata?
      if @metadata.nil?
        errors.add(:metadata, "is required for #{humanized_data_type}")
      else
        normalized = FieldDefinitionConcerns::MetafieldManipulator.normalize_for(data_type_enum, @metadata)
        unless normalized
          errors.add(:metadata, "invalid metadata structure for #{humanized_data_type}")
        end
      end
    else
      errors.add(:metadata, "not needed for #{humanized_data_type}") if @metadata
    end
  end

  macro included
    before_validation :coerce_and_normalize!
    validate :validate_normalized_metadata_structure
  end
end
