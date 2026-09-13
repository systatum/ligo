module FieldValueConcerns::Finder
  extend self

  def filter(*, resource_type : Int32 | Int64)
    super(resource_type: resource_type.to_i64)
  end

  def filter(*, resource_type : Int32 | Int64, field : Ligo::FieldDefinition)
    super(field_def: field, resource_type: resource_type.to_i64)
  end

  def filter(*, resource_id : Int64, resource_type : Int32 | Int64)
    super(resource_id: resource_id, resource_type: resource_type.to_i64)
  end

  def filter(*, field : Ligo::FieldDefinition, resource_id : Int64, resource_type : Int32 | Int64)
    super(field_def: field, resource_id: resource_id, resource_type: resource_type.to_i64)
  end

  def filter(*, resource_types : Array(Int32 | Int64))
    super(resource_type__in: resource_types.map(&.to_i64))
  end

  def filter(*, field : Ligo::FieldDefinition)
    super(field_def: field)
  end

  def search(query : String, resource_types : Array(Int32 | Int64)? = nil)
    base_query = all
    base_query = base_query.filter(resource_type__in: resource_types.map(&.to_i64)) if resource_types

    base_query.filter(
      Marten::DB::Query::Node.new(string_value__icontains: query) |
      Marten::DB::Query::Node.new(text_value__icontains: query)
    )
  end

  def for_resource(resource_id : Int64, resource_type : Int32 | Int64)
    filter(resource_id: resource_id, resource_type: resource_type.to_i64)
  end

  def for_resource_field(field_name : String, resource_id : Int64, resource_type : Int32 | Int64)
    field = Ligo::FieldDefinition.find_by_name_and_resource_type(field_name, resource_type)
    return nil unless field
    filter(
      field_def: field,
      resource_id: resource_id,
      resource_type: resource_type.to_i64
    ).first?
  end
end
