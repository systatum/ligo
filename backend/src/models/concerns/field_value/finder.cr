module FieldValueConcerns::Finder
  extend self

  def filter(*, resource_type : FieldResourceType)
    super(resource_type: resource_type.value.to_i64)
  end

  def filter(*, resource_type : FieldResourceType, field : FieldDefinition)
    super(resource_type: resource_type.value.to_i64, field_def: field)
  end

  def filter(*, resource_type : FieldResourceType, resource_id : Int64)
    super(resource_type: resource_type.value.to_i64, resource_id: resource_id)
  end

  def filter(*, resource_type : FieldResourceType, field : FieldDefinition, resource_id : Int64)
    super(resource_type: resource_type.value.to_i64, field_def: field, resource_id: resource_id)
  end

  def filter(*, resource_types : Array(FieldResourceType))
    super(resource_type__in: resource_types.map(&.value.to_i64))
  end

  def filter(*, field : FieldDefinition)
    super(field_def: field)
  end

  def search(query : String, resource_types : Array(FieldResourceType)? = nil)
    base_query = all
    base_query = base_query.filter(resource_type__in: resource_types.map(&.value.to_i64)) if resource_types

    string_results = base_query.filter(string_value__icontains: query)

    string_results
  end

  def for_resource(resource_type : FieldResourceType, resource_id : Int64)
    filter(resource_type: resource_type.value.to_i64, resource_id: resource_id)
  end

  def for_resource_field(resource_type : FieldResourceType, resource_id : Int64, field_name : String)
    field = FieldDefinition.find_by_name_and_resource_type(field_name, resource_type)
    return nil unless field
    filter(
      resource_type: resource_type.value.to_i64,
      resource_id: resource_id,
      field_def: field
    ).first?
  end
end
