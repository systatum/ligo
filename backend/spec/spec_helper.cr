ENV["MARTEN_ENV"] = "test"

require "spectator"

require "../src/project"
require "marten/spec"
require "./factories/**"
require "../src/lib/**"
require "../src/cli/migrate_system_fields"

# We define configs for Spectator (a spec framework built on
# top of Crystal's spec) to handle custom behaviours and other things
# that Marten would otherwise handle automatically with Crystal spec
Spectator.configure do |config|
  # This hook should also apply to the default specs because
  # this is also fired once before the entire test run
  config.before_suite do
    SystemFieldsMigrator.migrate!
  end

  # However, this hook is only scoped to Spectator's own spec runner
  # which doesn't have test isolation already set up as Marten did,
  # so we apply our own per-case data flushing here (in the exact same
  # way as Marten v0.6.0).
  config.after_each do
    Marten::DB::Connection.registry.values.each do |conn|
      Marten::DB::Management::SchemaEditor.run_for(conn) do |schema_editor|
        schema_editor.flush_model_tables
      end
    end
  end
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
