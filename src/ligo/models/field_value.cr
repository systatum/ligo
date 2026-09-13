module Ligo
  class FieldValue < Marten::Model
    include SoftDeleter

    alias FVC = FieldValueConcerns
    extend FVC::Updater
    extend FVC::Finder
    include FVC::ValueManipulator

    field :id, :uuid, primary_key: true
    field :field_def, :many_to_one, to: Ligo::FieldDefinition, null: false
    field :resource_id, :big_int, null: false
    field :resource_type, :int, null: false

    def initialize(
      *,
      field : Ligo::FieldDefinition? = nil,
      resource_id : Int64? = nil,
      resource_type : Int32 | Int64 | Nil = nil,
      string_value : String? = nil,
      text_value : String? = nil,
      integer_value : Int64? = nil,
      float_value : Float64? = nil,
      date_value : Time? = nil,
      time_value : Time? = nil,
      datetime_value : Time? = nil,
      boolean_value : Bool? = nil,
    )
      super(
        field_def: field,
        resource_id: resource_id,
        resource_type: resource_type.try(&.to_i64),
        string_value: string_value,
        text_value: text_value,
        integer_value: integer_value,
        float_value: float_value,
        date_value: date_value,
        time_value: time_value,
        datetime_value: datetime_value,
        boolean_value: boolean_value
      )
    end

    field :string_value, :string, max_size: 255, null: true, blank: true
    field :text_value, :text, null: true, blank: true
    field :integer_value, :big_int, null: true, blank: true
    field :float_value, :float, null: true, blank: true
    field :date_value, :date, null: true, blank: true
    field :time_value, :date_time, null: true, blank: true
    field :datetime_value, :date_time, null: true, blank: true
    field :boolean_value, :bool, null: true, blank: true

    field :created_at, :date_time, null: false, auto_now_add: true
    field :updated_at, :date_time, null: false, auto_now: true

    after_initialize :initialize_id

    validate :validate_unique_field_per_resource
    validate :validate_uniqueness_constraint

    db_unique_constraint :idx_field_value_field_def_resource_unique, field_names: [:field_def, :resource_id, :resource_type]

    private def initialize_id
      @id ||= UUID.random
    end

    private def validate_unique_field_per_resource
      existing = Ligo::FieldValue.filter(
        field_def: field_def,
        resource_id: resource_id,
        resource_type: resource_type!
      )
      existing = existing.exclude(id: id) if persisted?

      if existing.exists?
        errors.add(:base, "Only one value per field per resource is allowed")
      end
    end

    private def validate_uniqueness_constraint
      field = field_def
      return unless field
      value = actual_value

      case field.uniqueness
      when FieldUniqueness::UNIQUELESS
        return
      when FieldUniqueness::UNIQUE_ALWAYS
        existing =
          case field.data_type_enum
          when FieldDataType::DTYPE_STRING
            Ligo::FieldValue.filter(field_def: field_def, resource_type: resource_type!, string_value: value)
          when FieldDataType::DTYPE_TEXT
            Ligo::FieldValue.filter(field_def: field_def, resource_type: resource_type!, text_value: value)
          when FieldDataType::DTYPE_INT
            Ligo::FieldValue.filter(field_def: field_def, resource_type: resource_type!, integer_value: value)
          when FieldDataType::DTYPE_FLOAT
            Ligo::FieldValue.filter(field_def: field_def, resource_type: resource_type!, float_value: value)
          when FieldDataType::DTYPE_DATE
            Ligo::FieldValue.filter(field_def: field_def, resource_type: resource_type!, date_value: value)
          when FieldDataType::DTYPE_TIME
            Ligo::FieldValue.filter(field_def: field_def, resource_type: resource_type!, time_value: value)
          when FieldDataType::DTYPE_DATETIME
            Ligo::FieldValue.filter(field_def: field_def, resource_type: resource_type!, datetime_value: value)
          when FieldDataType::DTYPE_BOOLEAN
            Ligo::FieldValue.filter(field_def: field_def, resource_type: resource_type!, boolean_value: value)
          else
            Ligo::FieldValue.all.filter(id: -1)
          end
        existing = existing.exclude(id: id) if persisted?
        if existing.exists?
          errors.add(:base, "Value must be unique for this field across all resources")
        end
      when FieldUniqueness::UNIQUE_FILL
        return if blank_value?(value)
        existing =
          case field.data_type_enum
          when FieldDataType::DTYPE_STRING
            Ligo::FieldValue.filter(field_def: field_def, resource_type: resource_type!, string_value: value)
          when FieldDataType::DTYPE_TEXT
            Ligo::FieldValue.filter(field_def: field_def, resource_type: resource_type!, text_value: value)
          when FieldDataType::DTYPE_INT
            Ligo::FieldValue.filter(field_def: field_def, resource_type: resource_type!, integer_value: value)
          when FieldDataType::DTYPE_FLOAT
            Ligo::FieldValue.filter(field_def: field_def, resource_type: resource_type!, float_value: value)
          when FieldDataType::DTYPE_DATE
            Ligo::FieldValue.filter(field_def: field_def, resource_type: resource_type!, date_value: value)
          when FieldDataType::DTYPE_TIME
            Ligo::FieldValue.filter(field_def: field_def, resource_type: resource_type!, time_value: value)
          when FieldDataType::DTYPE_DATETIME
            Ligo::FieldValue.filter(field_def: field_def, resource_type: resource_type!, datetime_value: value)
          when FieldDataType::DTYPE_BOOLEAN
            Ligo::FieldValue.filter(field_def: field_def, resource_type: resource_type!, boolean_value: value)
          else
            Ligo::FieldValue.all.filter(id: -1)
          end
        existing = existing.exclude(id: id) if persisted?
        if existing.exists?
          errors.add(:base, "Value must be unique for this field (unless blank)")
        end
      end
    end
  end
end
