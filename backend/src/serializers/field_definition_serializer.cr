class FieldDefinitionSerializer
  def self.dump(resource_type : FieldResourceType) : Array(Hash(String, JSON::Any))
    fields = FieldDefinition.filter(resource_type: resource_type)

    fields.map do |field|
      {
        "id"      => JSON::Any.new(field.hashed_id),
        "native"  => JSON::Any.new(field.is_system_field),
        "caption" => build_caption(field),
        "type"    => JSON::Any.new(field.data_type_enum.to_s),
      }
    end
  end

  def self.dump(resource_type : Int32) : Array(Hash(String, JSON::Any))
    rt = FieldResourceType.from_value?(resource_type)
    raise ArgumentError.new("Invalid resource_type: #{resource_type}") unless rt
    dump(rt)
  end

  private def self.build_caption(field : FieldDefinition) : JSON::Any
    localized_name = field.localized_name
    return JSON::Any.new({"en" => JSON::Any.new("")}) unless localized_name

    caption = {} of String => JSON::Any
    caption["en"] = JSON::Any.new(localized_name.english || "")
    caption["id"] = JSON::Any.new(localized_name.indonesian || "") if localized_name.indonesian
    caption["ja"] = JSON::Any.new(localized_name.japanese || "") if localized_name.japanese

    JSON::Any.new(caption)
  end
end
