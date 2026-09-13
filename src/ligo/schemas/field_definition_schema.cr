class FieldDefinitionSchema < BaseSchema
  field :resource_type, :int, required: true
  field :name, :string, max_size: 255, required: true, strip: true
  field :data_type, :enum, values: FieldDataType, required: true
  field :localized_name, :json, required: false, serializable: LocalizedName
  field :nullable, :bool, required: false
  field :uniqueness, :enum, values: FieldUniqueness, required: false
  field :metadata, :json, required: false, serializable: FieldMetadata::Base

  before_validation :coerce_default_uniqueness

  private def coerce_default_uniqueness
    default_uniqueness = FieldUniqueness::UNIQUELESS.to_s
    @validated_data["uniqueness"] = self.uniqueness.to_s.presence || default_uniqueness
  end
end
