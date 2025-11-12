class FieldValue < Marten::Model
  include SoftDeleter

  field :id, :big_int, primary_key: true, auto: true
  field :field_id, :big_int, null: false, index: true
  field :resource_id, :big_int, null: false, index: true
  field :resource_type, :int, null: false, index: true

  def resource_type_enum : FieldResourceType
    rt_value = resource_type!
    unless rt_value >= Int32::MIN && rt_value <= Int32::MAX
      raise ArgumentError.new("resource_type value #{rt_value} is outside Int32 range")
    end

    rt_i32 = rt_value.to_i32
    FieldResourceType.from_value?(rt_i32) ||
      raise ArgumentError.new("Invalid resource_type value: #{rt_i32}. Valid values: #{FieldResourceType.values.map(&.value).join(", ")}")
  end

  def resource_type_enum=(value : FieldResourceType)
    self.resource_type = value.value.to_i64
  end

  def resource_type=(value : FieldResourceType)
    @resource_type = value.value.to_i64
  end

  def initialize(
    *,
    field_id : Int64? = nil,
    resource_id : Int64? = nil,
    resource_type : FieldResourceType,
    string_value : String? = nil,
    integer_value : Int64? = nil,
    float_value : Float64? = nil,
    date_value : Time? = nil,
    time_value : Time? = nil,
    datetime_value : Time? = nil,
    boolean_value : Bool? = nil,
  )
    super(
      field_id: field_id,
      resource_id: resource_id,
      resource_type: resource_type.value.to_i64,
      string_value: string_value,
      integer_value: integer_value,
      float_value: float_value,
      date_value: date_value,
      time_value: time_value,
      datetime_value: datetime_value,
      boolean_value: boolean_value
    )
  end

  def initialize(
    *,
    field_id : Int32,
    resource_id : Int64? = nil,
    resource_type : FieldResourceType,
    string_value : String? = nil,
    integer_value : Int64? = nil,
    float_value : Float64? = nil,
    date_value : Time? = nil,
    time_value : Time? = nil,
    datetime_value : Time? = nil,
    boolean_value : Bool? = nil,
  )
    initialize(
      field_id: field_id.to_i64,
      resource_id: resource_id,
      resource_type: resource_type,
      string_value: string_value,
      integer_value: integer_value,
      float_value: float_value,
      date_value: date_value,
      time_value: time_value,
      datetime_value: datetime_value,
      boolean_value: boolean_value
    )
  end

  def initialize(
    *,
    field_id : Int64? = nil,
    resource_id : Int64? = nil,
    resource_type : Int64? = nil,
    string_value : String? = nil,
    integer_value : Int64? = nil,
    float_value : Float64? = nil,
    date_value : Time? = nil,
    time_value : Time? = nil,
    datetime_value : Time? = nil,
    boolean_value : Bool? = nil,
  )
    super(
      field_id: field_id,
      resource_id: resource_id,
      resource_type: resource_type,
      string_value: string_value,
      integer_value: integer_value,
      float_value: float_value,
      date_value: date_value,
      time_value: time_value,
      datetime_value: datetime_value,
      boolean_value: boolean_value
    )
  end

  def self.filter(*, resource_type : FieldResourceType)
    super(resource_type: resource_type.value.to_i64)
  end

  def self.filter(*, resource_type : FieldResourceType, field_id : Int64)
    super(resource_type: resource_type.value.to_i64, field_id: field_id)
  end

  def self.filter(*, resource_type : FieldResourceType, resource_id : Int64)
    super(resource_type: resource_type.value.to_i64, resource_id: resource_id)
  end

  def self.filter(*, resource_type : FieldResourceType, field_id : Int64, resource_id : Int64)
    super(resource_type: resource_type.value.to_i64, field_id: field_id, resource_id: resource_id)
  end

  def self.filter(*, resource_type__in : Array(FieldResourceType))
    super(resource_type__in: resource_type__in.map(&.value.to_i64))
  end

  private def resource_type! : Int64
    rt = @resource_type
    case rt
    when Int64
      rt
    when Int32
      rt.to_i64
    when String
      s = rt.as(String)
      if (ival = s.to_i64?)
        ival
      elsif RESOURCE_TYPE_MAP.has_key?(s.upcase)
        RESOURCE_TYPE_MAP[s.upcase]
      else
        raise ArgumentError.new("Invalid resource_type string: '#{s}'. Must be a valid integer or one of: #{RESOURCE_TYPE_MAP.keys.join(", ")}")
      end
    else
      raise TypeCastError.new("resource_type must be Int64, Int32, or String, got: #{rt.class}")
    end
  end

  field :string_value, :text, null: true, blank: true
  field :integer_value, :big_int, null: true, blank: true
  field :float_value, :float, null: true, blank: true
  field :date_value, :date, null: true, blank: true
  field :time_value, :date_time, null: true, blank: true
  field :datetime_value, :date_time, null: true, blank: true
  field :boolean_value, :bool, null: true, blank: true

  field :created_at, :date_time, null: false, auto_now_add: true
  field :updated_at, :date_time, null: false, auto_now: true

  after_initialize :coerce_resource_type!

  RESOURCE_TYPE_MAP = FieldResourceType.values.to_h { |v| {v.to_s.upcase, v.value.to_i64} }

  validate :validate_unique_field_per_resource
  validate :validate_uniqueness_constraint

  private def coerce_resource_type!
    rt = @resource_type
    return if rt.nil?
    case rt
    when Int64, Int32
      return
    when String
      s = rt.as(String)
      if (ival = s.to_i64?)
        @resource_type = ival
        return
      end
      upper = s.upcase
      if RESOURCE_TYPE_MAP.has_key?(upper)
        @resource_type = RESOURCE_TYPE_MAP[upper]
      else
        raise ArgumentError.new("Unknown resource_type string: '#{s}'. Valid types: #{RESOURCE_TYPE_MAP.keys.join(", ")}")
      end
    end
  end

  private def validate_unique_field_per_resource
    existing = FieldValue.filter(
      field_id: field_id,
      resource_type: resource_type!,
      resource_id: resource_id
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
        case field.data_type.not_nil!
        when FieldDataType::DTYPE_STRING
          FieldValue.filter(field_id: field_id, resource_type: resource_type!, string_value: value)
        when FieldDataType::DTYPE_INT
          FieldValue.filter(field_id: field_id, resource_type: resource_type!, integer_value: value)
        when FieldDataType::DTYPE_FLOAT
          FieldValue.filter(field_id: field_id, resource_type: resource_type!, float_value: value)
        when FieldDataType::DTYPE_DATE
          FieldValue.filter(field_id: field_id, resource_type: resource_type!, date_value: value)
        when FieldDataType::DTYPE_TIME
          FieldValue.filter(field_id: field_id, resource_type: resource_type!, time_value: value)
        when FieldDataType::DTYPE_DATETIME
          FieldValue.filter(field_id: field_id, resource_type: resource_type!, datetime_value: value)
        when FieldDataType::DTYPE_BOOLEAN
          FieldValue.filter(field_id: field_id, resource_type: resource_type!, boolean_value: value)
        else
          FieldValue.all.filter(id: -1)
        end
      existing = existing.exclude(id: id) if persisted?
      if existing.exists?
        errors.add(:base, "Value must be unique for this field across all resources")
      end
    when FieldUniqueness::UNIQUE_FILL
      return if blank_value?(value)
      existing =
        case field.data_type.not_nil!
        when FieldDataType::DTYPE_STRING
          FieldValue.filter(field_id: field_id, resource_type: resource_type!, string_value: value)
        when FieldDataType::DTYPE_INT
          FieldValue.filter(field_id: field_id, resource_type: resource_type!, integer_value: value)
        when FieldDataType::DTYPE_FLOAT
          FieldValue.filter(field_id: field_id, resource_type: resource_type!, float_value: value)
        when FieldDataType::DTYPE_DATE
          FieldValue.filter(field_id: field_id, resource_type: resource_type!, date_value: value)
        when FieldDataType::DTYPE_TIME
          FieldValue.filter(field_id: field_id, resource_type: resource_type!, time_value: value)
        when FieldDataType::DTYPE_DATETIME
          FieldValue.filter(field_id: field_id, resource_type: resource_type!, datetime_value: value)
        when FieldDataType::DTYPE_BOOLEAN
          FieldValue.filter(field_id: field_id, resource_type: resource_type!, boolean_value: value)
        else
          FieldValue.all.filter(id: -1)
        end
      existing = existing.exclude(id: id) if persisted?
      if existing.exists?
        errors.add(:base, "Value must be unique for this field (unless blank)")
      end
    end
  end

  def value(field_data_type : FieldDataType)
    case field_data_type
    when FieldDataType::DTYPE_STRING
      string_value
    when FieldDataType::DTYPE_INT
      integer_value
    when FieldDataType::DTYPE_FLOAT
      float_value
    when FieldDataType::DTYPE_DATE
      date_value
    when FieldDataType::DTYPE_TIME
      time_value
    when FieldDataType::DTYPE_DATETIME
      datetime_value
    when FieldDataType::DTYPE_BOOLEAN
      boolean_value
    else
      nil
    end
  end

  def field_def
    FieldDefinition.get(id: field_id)
  end

  def actual_value
    string_value ||
      integer_value ||
      float_value ||
      date_value ||
      time_value ||
      datetime_value ||
      boolean_value
  end

  private def blank_value?(value)
    value.nil? || (value.responds_to?(:empty?) && value.empty?)
  end

  def set_value(val, field_data_type : FieldDataType)
    clear_all_values

    case field_data_type
    when FieldDataType::DTYPE_STRING
      self.string_value = val.try(&.to_s)
    when FieldDataType::DTYPE_INT
      self.integer_value =
        if val.is_a?(Int64)
          val
        elsif val.is_a?(Int32)
          val.to_i64
        else
          val.try(&.to_s).try { |s| s.to_i64? }
        end
    when FieldDataType::DTYPE_FLOAT
      self.float_value =
        if val.is_a?(Float64)
          val
        elsif val.is_a?(Float32)
          val.to_f64
        elsif val.is_a?(Int64) || val.is_a?(Int32)
          val.to_f64
        else
          val.try(&.to_s).try { |s| s.to_f64? }
        end
    when FieldDataType::DTYPE_DATE
      self.date_value =
        if val.is_a?(Time)
          Time.utc(val.year, val.month, val.day)
        else
          val.try(&.to_s).try { |s| Time.parse(s, "%Y-%m-%d", Time::Location::UTC) }
        end
    when FieldDataType::DTYPE_TIME
      self.time_value = val.is_a?(Time) ? val : val.try(&.to_s).try { |s| Time.parse(s, "%H:%M:%S", Time::Location::UTC) }
    when FieldDataType::DTYPE_DATETIME
      self.datetime_value =
        if val.is_a?(Time)
          val
        else
          val.try(&.to_s).try { |s| Time.parse(s, "%Y-%m-%dT%H:%M:%S", Time::Location::UTC) }
        end
    when FieldDataType::DTYPE_BOOLEAN
      self.boolean_value = val.try { |v| v.to_s.downcase.in?(["true", "1", "yes"]) }
    end
  end

  def self.search(query : String, resource_types : Array(FieldResourceType)? = nil)
    base_query = all
    base_query = base_query.filter(resource_type__in: resource_types.map(&.value.to_i64)) if resource_types

    string_results = base_query.filter(string_value__icontains: query)

    string_results
  end

  def self.for_resource(resource_type : FieldResourceType, resource_id : Int64)
    filter(resource_type: resource_type.value.to_i64, resource_id: resource_id)
  end

  def self.for_resource_field(resource_type : FieldResourceType, resource_id : Int64, field_name : String)
    field = FieldDefinition.find_by_name_and_resource_type(field_name, resource_type)
    return nil unless field
    filter(
      resource_type: resource_type.value.to_i64,
      resource_id: resource_id,
      field_id: field.id
    ).first?
  end

  private def clear_all_values
    self.string_value = nil
    self.integer_value = nil
    self.float_value = nil
    self.date_value = nil
    self.time_value = nil
    self.datetime_value = nil
    self.boolean_value = nil
  end
end
