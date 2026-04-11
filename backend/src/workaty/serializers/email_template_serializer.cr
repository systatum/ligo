module Workaty
  class EmailTemplateSerializer < ModelSerializer
    protected def fields
      record = @record.as(EmailTemplate)

      {
        id: record.hashed_id,
      }
    end

    def self.serialize_with_fields(
      records : Array(Workaty::EmailTemplate),
      resource_type : FieldResourceType,
    ) : String
      fields_data = FieldDefinition.filter(resource_type: resource_type).map do |f|
        FieldDefinitionSerializer.dump(f)
      end

      records_data = {} of String => Array(Hash(String, JSON::Any))
      records_data[resource_type.to_s] = records.map do |record|
        serialize_record(record, resource_type)
      end

      result = {
        "records" => records_data,
        "fields"  => {resource_type.to_s => fields_data},
      }

      result.to_json
    end

    def self.serialize_with_fields(
      record : Workaty::EmailTemplate,
      resource_type : FieldResourceType,
    ) : String
      serialize_with_fields([record], resource_type)
    end

    private def self.serialize_record(
      record : Workaty::EmailTemplate,
      resource_type : FieldResourceType,
    ) : Hash(String, JSON::Any)
      result = {} of String => JSON::Any

      result["id"] = JSON::Any.new(record.hashed_id)
      result["title"] = JSON::Any.new(record.title)
      result["content"] = JSON::Any.new(record.content)

      field_values = FieldValue.for_resource(record.id.as(Int64), resource_type)
      field_values.each do |fv|
        field_def = fv.field_def
        next unless field_def

        actual_value = fv.actual_value
        result[field_def.name!] =
          case actual_value
          when String
            JSON::Any.new(actual_value)
          when Int64
            JSON::Any.new(actual_value)
          when Float64
            JSON::Any.new(actual_value)
          when Bool
            JSON::Any.new(actual_value)
          when Nil
            JSON::Any.new(nil)
          else
            JSON::Any.new(actual_value.to_s)
          end
      end

      result
    end
  end
end
