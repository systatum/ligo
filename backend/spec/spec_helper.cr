ENV["MARTEN_ENV"] = "test"

require "spec"

require "../src/project"
require "marten/spec"
require "./factories/**"
require "../src/lib/**"
require "../src/cli/migrate_system_fields"

Spec.before_suite do
  SystemFieldsMigrator.migrate!
end

def date_time_format
  /\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z/
end

def create_field(name : String, data_type : FieldDataType) : FieldDefinition
  FieldDefinition.new(
    name: name,
    resource_type: FieldResourceType::CANDIDATE,
    data_type: data_type,
    is_system_field: false
  ).tap(&.save!)
end
