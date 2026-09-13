class ModelSerializer
  @record : Marten::Model

  def self.serialize(record)
    serializer = new(record)
    serializer.serialize_to_json
  end

  # not printing as a JSON string, but as a map
  def self.soft_serialize(record)
    serializer = new(record)
    serializer.soft_serialize
  end

  # -------------------

  def initialize(record)
    @record = record
  end

  def soft_serialize
    fields.merge(timing_fields)
  end

  def serialize_to_json : String
    soft_serialize.to_json
  end

  protected def fields
    NamedTuple.new
  end

  # Resolves an ordered list of UploadedFile id strings into their
  # serialized form, in order.
  protected def fetch_uploaded_files(ids : Array(String)?)
    ids = ids || [] of String
    files_by_id = Ligo::UploadedFile.filter(
      id__in: ids.map { |id| UUID.new(id) }
    ).index_by(&.id.to_s)

    ids.compact_map { |id| files_by_id[id]? }.map do |file|
      UploadedFileSerializer.soft_serialize(file)
    end
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
