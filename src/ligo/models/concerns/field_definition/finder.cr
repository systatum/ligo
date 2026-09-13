module FieldDefinitionConcerns::Finder
  extend self

  def filter(*, resource_type : Int32 | Int64)
    super(resource_type: resource_type.to_i64)
  end

  def filter(*, resource_type : Int32 | Int64, name : String)
    super(resource_type: resource_type.to_i64, name: name)
  end

  def filter(*, resource_type : Int32 | Int64, is_system_field : Bool)
    super(resource_type: resource_type.to_i64, is_system_field: is_system_field)
  end

  def filter(*, resource_type : Int32 | Int64, name : String, is_system_field : Bool)
    super(resource_type: resource_type.to_i64, name: name, is_system_field: is_system_field)
  end

  def filter(*, resource_types : Array(Int32 | Int64))
    super(resource_type__in: resource_types.map(&.to_i64))
  end

  def for_resource_type(resource_type : Int32 | Int64)
    filter(resource_type: resource_type.to_i64)
  end

  def find_by_name_and_resource_type(name : String, resource_type : Int32 | Int64)
    for_resource_type(resource_type).filter(name: name).first?
  end
end
