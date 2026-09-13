module Ligo
  class Changelog < Marten::Model
    field :id, :big_int, primary_key: true, auto: true
    field :action_type, :enum, values: ActionType, null: false, blank: false
    field :record_class, :string, max_size: 255, null: false, blank: false
    field :record_id, :big_int, null: true, blank: true
    field :record_uuid, :uuid, null: true, blank: true
    field :changes, :json, null: true, blank: true
    field :performer_id, :big_int, null: true, blank: true
    field :created_at, :date_time, null: false, auto_now_add: true
    field :updated_at, :date_time, null: false, auto_now: true

    # Returns whichever identifier column
    # is set for this changelog record.
    # Normal Int64-based PK takes priority.
    def record_identifier : Int32 | Int64 | UUID
      record_id || record_uuid || raise "Missing record identifier"
    end

    # Persists the given ID to the correct
    # column according to its type.
    def record_identifier=(id : Int32 | Int64 | UUID)
      case id
      when UUID
        self.record_id = nil
        self.record_uuid = id
      when Int64
        self.record_id = id
        self.record_uuid = nil
      else
        raise "Unsupported primary key type for change tracking: #{id.class}"
      end
    end

    enum ActionType
      CREATE
      UPDATE
      DELETE
    end

    validate :validate_record_identifier_presence

    private def validate_record_identifier_presence
      return unless record_id.nil? && record_uuid.nil?
      errors.add(:base, "either record_id or record_uuid must be present")
    end
  end
end
