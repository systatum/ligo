module FieldDefinitionConcerns::Coercer
  include FieldEnumCoercer

  field_enum_coercer :data_type, FieldDataType

  def coerce_metadata!
    # Non-meta types does not need metadata
    @metadata = nil if !need_metadata?
  end

  def choice_metadata! : FieldMetadata::Choice
    @metadata.as(FieldMetadata::Choice)
  end

  def file_metadata! : FieldMetadata::File
    @metadata.as(FieldMetadata::File)
  end

  def coerce!
    coerce_data_type!
    coerce_metadata!
  end

  macro included
    before_validation :coerce!
    after_initialize :coerce!
  end
end
