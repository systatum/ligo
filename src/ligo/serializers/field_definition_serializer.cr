class FieldDefinitionSerializer
  # Soft serialize a single FieldDefinition instance
  def self.dump(field : Ligo::FieldDefinition) : Hash(String, JSON::Any)
    {
      "id"      => JSON::Any.new(field.hashed_id),
      "native"  => JSON::Any.new(field.is_system_field),
      "caption" => build_caption(field),
      "type"    => JSON::Any.new(field.data_type_enum.to_s),
    }
  end

  private def self.build_caption(field : Ligo::FieldDefinition) : JSON::Any
    localized_name = field.localized_name
    return JSON::Any.new({"en" => JSON::Any.new("")}) unless localized_name

    caption = {} of String => JSON::Any
    caption["en"] = JSON::Any.new(localized_name.english || "")
    caption["id"] = JSON::Any.new(localized_name.indonesian || "") if localized_name.indonesian
    caption["ja"] = JSON::Any.new(localized_name.japanese || "") if localized_name.japanese

    JSON::Any.new(caption)
  end
end
