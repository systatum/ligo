module FieldDefinitionConcerns::Finder
  extend self

  def filter(*, resource_type : FieldResourceType)
    FieldDefinition.filter(resource_type: resource_type.value.to_i64)
  end

  def filter(*, resource_type : FieldResourceType, name : String)
    FieldDefinition.filter(resource_type: resource_type.value.to_i64, name: name)
  end

  def filter(*, resource_type : FieldResourceType, is_system_field : Bool)
    FieldDefinition.filter(resource_type: resource_type.value.to_i64, is_system_field: is_system_field)
  end

  def filter(*, resource_type : FieldResourceType, name : String, is_system_field : Bool)
    FieldDefinition.filter(resource_type: resource_type.value.to_i64, name: name, is_system_field: is_system_field)
  end

  def filter(*, resource_types : Array(FieldResourceType))
    FieldDefinition.filter(resource_type__in: resource_types.map(&.value.to_i64))
  end

  def for_resource_type(resource_type : FieldResourceType)
    FieldDefinition.filter(resource_type: resource_type.value.to_i64)
  end

  def find_by_name_and_resource_type(name : String, resource_type : FieldResourceType)
    for_resource_type(resource_type).filter(name: name).first?
  end
end
