# This module can be included to any model. What would happen is that,
# when that model is created, updated or deleted, we will take note
# of those actions along with the state of the date
module ChangeTracker
  alias TrackableType = String | Bool | Int32 | Int64 | Nil

  class ChangeRecord
    property type : String | Nil = nil
    property current_value : TrackableType = nil
    property old_value : TrackableType = nil

    def to_tupple
      {
        type:          type,
        current_value: current_value,
        old_value:     old_value,
      }
    end
  end

  macro included
    @initial_record_values = {} of String => ChangeRecord

    after_initialize :track_initial_record_values
    after_create :track_record_creation
    after_update :track_record_update
    before_delete :track_record_deletion
  end

  private def track_record_event(action_type : Changelog::ActionType)
    changelog = Changelog.new(action_type: action_type)
    changelog.record_class = self.class.to_s
    changelog.record_id = self.id
    changelog.changes = changed_record_values
    changelog.save!

    # refresh the snapshot
    take_fields_snapshot into: @initial_record_values

    nil
  end

  private def track_record_creation
    track_record_event(Changelog::ActionType::CREATE)
  end

  private def track_record_update
    track_record_event(Changelog::ActionType::UPDATE)
  end

  private def track_record_deletion
    track_record_event(Changelog::ActionType::DELETE)
  end

  private def track_initial_record_values
    take_fields_snapshot into: @initial_record_values
  end

  # find out what has been changed
  private def changed_record_values
    delta = {} of String => NamedTuple(type: String | Nil, current_value: TrackableType, old_value: TrackableType)
    current_values = self.local_field_db_values

    @initial_record_values.each do |field_name, change_record|
      current_value = sanitize_value(current_values[field_name])
      next if change_record.old_value == current_value
      change_record.current_value = current_value
      delta[field_name] = change_record.to_tupple
    end

    delta.to_json
  end

  SKIPPED_FIELDS = %w(
    created_at
    updated_at
    password
    password_updated_at
  )

  private def take_fields_snapshot(into kv)
    local_values = self.local_field_db_values

    self.class.fields.each do |field|
      field_name = field.id

      # skip created_at and updated_at field
      next if SKIPPED_FIELDS.includes?(field_name)

      rec = ChangeRecord.new
      kv[field_name] = rec
      rec.old_value = sanitize_value(local_values[field_name])

      # start recording the value
      if field.is_a?(Marten::DB::Field::String) || field.is_a?(Marten::DB::Field::Text)
        rec.type = "text"
      elsif field.is_a?(Marten::DB::Field::Int) || field.is_a?(Marten::DB::Field::BigInt)
        rec.type = "int"
      elsif field.is_a?(Marten::DB::Field::Float)
        rec.type = "decimal"
      elsif field.is_a?(Marten::DB::Field::Date)
        rec.type = "date"
      elsif field.is_a?(Marten::DB::Field::DateTime)
        rec.type = "datetime"
      elsif field.is_a?(Marten::DB::Field::Bool)
        rec.type = "boolean"
      end
    end
  end

  private def sanitize_value(value) : TrackableType
    return nil if value.nil?

    case value
    when String
      value.as(String)
    when Int32
      value.as(Int32)
    when Int64
      value.as(Int64)
    when Float32
      value.as(Float32).to_s
    when Float64
      value.as(Float64).to_s
    when Time
      value.as(Time).to_s
    when Bool
      value.as(Bool)
    else
      value.to_s
    end
  end
end
