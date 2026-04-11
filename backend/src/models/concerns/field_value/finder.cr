module FieldValueConcerns::Finder
  extend self

  def filter(*, resource_type : FieldResourceType)
    super(resource_type: resource_type.value.to_i64)
  end

  def filter(*, resource_type : FieldResourceType, field : FieldDefinition)
    super(field_def: field, resource_type: resource_type.value.to_i64)
  end

  def filter(*, resource_id : Int64, resource_type : FieldResourceType)
    super(resource_id: resource_id, resource_type: resource_type.value.to_i64)
  end

  def filter(*, field : FieldDefinition, resource_id : Int64, resource_type : FieldResourceType)
    super(field_def: field, resource_id: resource_id, resource_type: resource_type.value.to_i64)
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

    base_query.filter(
      Marten::DB::Query::Node.new(string_value__icontains: query) |
      Marten::DB::Query::Node.new(text_value__icontains: query)
    )
  end

  def for_resource(resource_id : Int64, resource_type : FieldResourceType)
    filter(resource_id: resource_id, resource_type: resource_type.value.to_i64)
  end

  def for_resource_field(field_name : String, resource_id : Int64, resource_type : FieldResourceType)
    field = FieldDefinition.find_by_name_and_resource_type(field_name, resource_type)
    return nil unless field
    filter(
      field_def: field,
      resource_id: resource_id,
      resource_type: resource_type.value.to_i64
    ).first?
  end
end
