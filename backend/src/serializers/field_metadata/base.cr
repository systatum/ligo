module FieldMetadata
  abstract class Base
    include JSON::Serializable

    use_json_discriminator "type", {
      choice: FieldMetadata::Choice,
      file:   FieldMetadata::File,
    }

    property type : String
  end
end
