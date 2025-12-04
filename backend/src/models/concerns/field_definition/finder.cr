module FieldDefinitionConcerns::Finder
  extend self

  def for_resource_type(resource_type : FieldResourceType)
    FieldDefinition.filter(resource_type: resource_type.value.to_i64)
  end

  def for_resource_type_i32(resource_type : Int32)
    FieldDefinition.filter(resource_type: resource_type.to_i64)
  end

  def for_resource_types(resource_types : Array(FieldResourceType))
    FieldDefinition.filter(resource_type__in: resource_types.map(&.value.to_i64))
  end

  def system_for_resource(resource_type : FieldResourceType)
    by_resource_type(resource_type).filter(is_system_field: true)
  end

  def user_for_resource(resource_type : FieldResourceType)
    by_resource_type(resource_type).filter(is_system_field: false)
  end

  def find_by_name_and_resource_type(name : String, resource_type : FieldResourceType)
    for_resource_type(resource_type).filter(name: name).first?
  end

  def find_by_name_and_resource_type_i32(name : String, resource_type : Int32)
    for_resource_type_i32(resource_type).filter(name: name).first?
  end

  def by_data_type(data_type : FieldDataType)
    FieldDefinition.filter(data_type: data_type)
  end

  def by_name_like(pattern : String)
    FieldDefinition.filter(name__like: pattern)
  end

  def system_field_by_name(name : String, resource_type : FieldResourceType)
    system_for_resource(resource_type).filter(name: name).first?
  end
end
