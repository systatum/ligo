module FieldMetadata
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

  def self.to_metadata_type!(dt : FieldDataType) : String
    if CHOICE_DTYPES.includes?(dt)
      "choice"
    elsif FILE_DTYPES.includes?(dt)
      "file"
    else
      raise "#{dt.humanized} is not expected to have metadata"
    end
  end
end
