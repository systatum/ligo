ENV["MARTEN_ENV"] = "test"

require "spectator"

require "../src/project"
require "marten/spec"

def flush_db_for_specs!
  Marten::DB::Connection.registry.values.each do |conn|
    Marten::DB::Management::SchemaEditor.run_for(conn) do |schema_editor|
      schema_editor.flush_model_tables
    end
  end
end

Spectator.configure do |config|
  config.after_each do
    flush_db_for_specs!
  end
end

Spec.after_each do
  # No need to flush db here as it's already done automatically by Marten
end

def create_user(email : String = "test-#{Random::Secure.hex(4)}@example.com") : Ligo::User
  user = Ligo::User.new(
    email: email,
    first_name: "Test",
    last_name: "User",
    password_updated_at: Time.utc
  )
  user.set_password("secret123")
  user.save!
  user
end
