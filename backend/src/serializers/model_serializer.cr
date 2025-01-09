class ModelSerializer
  @record : Marten::Model

  def self.serialize(record)
    serializer = new(record)
    serializer.serialize_to_json
  end

  def initialize(record)
    @record = record
  end

  def serialize_to_json : String
    return fields.merge(timing_fields).to_json
  end

  protected def fields
    NamedTuple.new()
  end

  private def timing_fields
    local_values = @record.local_field_db_values
    has_created_at = local_values.has_key? "created_at"
    has_updated_at = local_values.has_key? "updated_at"
    has_deleted_at = local_values.has_key? "deleted_at"

    created_at : Time | Nil
    updated_at : Time | Nil
    deleted_at : Time | Nil

    created_at = local_values["created_at"].as?(Time) if has_created_at
    updated_at = local_values["updated_at"].as?(Time) if has_updated_at
    deleted_at = local_values["deleted_at"].as?(Time) if has_deleted_at

    {
      created_at: created_at,
      updated_at: updated_at,
      deleted_at: deleted_at,
    }
  end
end
