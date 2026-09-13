module FieldValueConcerns::Updater
  extend self

  def update!(resource : Marten::Model, form : FormPayload, resource_type : Int32 | Int64) : Bool
    resource_id = resource.id.as(Int64)

    field_defs_map = field_definitions_of(resource_type)

    existing_values_map = values_of(resource_type, resource_id)

    resource.transaction do
      form.dynamic_fields.each do |field_identifier, value|
        field_def = field_defs_map[field_identifier]?
        next unless field_def

        update_or_create_field_value(resource_id, field_def, value, resource_type, existing_values_map)
      end
    end

    true
  end

  private def field_definitions_of(resource_type : Int32 | Int64)
    fields = Ligo::FieldDefinition.filter(resource_type: resource_type.to_i64)

    map = {} of String => Ligo::FieldDefinition
    fields.each do |f|
      map[f.name!] = f
      map[f.hashed_id] = f
    end
    map
  end

  private def values_of(resource_type : Int32 | Int64, resource_id : Int64)
    Ligo::FieldValue
      .filter(resource_id: resource_id, resource_type: resource_type.to_i64)
      .to_h { |fv| {Int64.new(fv.field_def.not_nil!.id!), fv} }
  end

  private def update_or_create_field_value(
    resource_id : Int64,
    field_def : Ligo::FieldDefinition,
    value : JSON::Any,
    resource_type : Int32 | Int64,
    existing_values_map : Hash(Int64, Ligo::FieldValue),
  )
    field_value = existing_values_map[field_def.id!]?

    if field_value
      field_value.value = value.raw
      field_value.save!
    else
      field_value = Ligo::FieldValue.new(
        field: field_def,
        resource_id: resource_id,
        resource_type: resource_type
      )
      field_value.value = value.raw
      field_value.save!
    end
  end
end
