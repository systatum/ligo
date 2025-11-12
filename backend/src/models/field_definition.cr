class FieldDefinition < Marten::Model
  include IdConcealer
  include SoftDeleter

  field :id, :big_int, primary_key: true, auto: true
  field :name, :string, max_size: 255, null: false, blank: false
  field :localized_name, :json, null: true, blank: true, serializable: LocalizedName
  field :resource_type, :int, null: false, index: true
  field :data_type, :enum, values: FieldDataType, null: false
  field :is_system_field, :bool, null: false, default: false
  field :nullable, :bool, null: false, default: true
  field :uniqueness, :enum, values: FieldUniqueness, null: false, default: FieldUniqueness::UNIQUELESS
  field :created_at, :date_time, null: false, auto_now_add: true
  field :updated_at, :date_time, null: false, auto_now: true

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
    name : String? = nil,
    resource_type : FieldResourceType,
    data_type : FieldDataType? = nil,
    nullable : Bool? = nil,
    uniqueness : FieldUniqueness? = nil,
    is_system_field : Bool? = nil,
    localized_name : LocalizedName? = nil,
  )
    super(name: name, resource_type: resource_type.value.to_i64)
    self.data_type = data_type if data_type
    self.nullable = nullable if !nullable.nil?
    self.uniqueness = uniqueness if uniqueness
    self.is_system_field = is_system_field if !is_system_field.nil?
    self.localized_name = localized_name if localized_name
  end

  def initialize(
    *,
    name : String? = nil,
    resource_type : Int64? = nil,
    data_type : FieldDataType? = nil,
    nullable : Bool? = nil,
    uniqueness : FieldUniqueness? = nil,
    is_system_field : Bool? = nil,
    localized_name : LocalizedName? = nil,
  )
    super(name: name, resource_type: resource_type)
    self.data_type = data_type if data_type
    self.nullable = nullable if !nullable.nil?
    self.uniqueness = uniqueness if uniqueness
    self.is_system_field = is_system_field if !is_system_field.nil?
    self.localized_name = localized_name if localized_name
  end

  def self.filter(*, resource_type : FieldResourceType)
    super(resource_type: resource_type.value.to_i64)
  end

  def self.filter(*, resource_type : FieldResourceType, name : String)
    super(resource_type: resource_type.value.to_i64, name: name)
  end

  def self.filter(*, resource_type : FieldResourceType, is_system_field : Bool)
    super(resource_type: resource_type.value.to_i64, is_system_field: is_system_field)
  end

  def self.filter(*, resource_type : FieldResourceType, name : String, is_system_field : Bool)
    super(resource_type: resource_type.value.to_i64, name: name, is_system_field: is_system_field)
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

  validate :validate_name_uniqueness_per_resource_type
  validate :validate_system_field_constraints

  scope :system_fields { filter(is_system_field: true) }
  scope :user_fields { filter(is_system_field: false) }

  def self.for_resource_type(resource_type : FieldResourceType)
    filter(resource_type: resource_type.value.to_i64)
  end

  def self.for_resource_type(resource_type : Int32)
    filter(resource_type: resource_type.to_i64)
  end

  after_initialize :store_original_name
  after_initialize :coerce_resource_type!

  RESOURCE_TYPE_MAP = FieldResourceType.values.to_h { |v| {v.to_s.upcase, v.value.to_i64} }

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

  private def validate_name_uniqueness_per_resource_type
    existing = self.class.filter(name: name, resource_type: resource_type!)
    existing = existing.exclude(id: id) if persisted?

    if existing.exists?
      errors.add(:name, "must be unique within the resource type")
    end
  end

  private def validate_system_field_constraints
    if system_field? && persisted? && name_changed?
      errors.add(:name, "cannot be changed for system fields")
    end
  end

  private def store_original_name
    @original_name = self.name
  end

  def refresh_original_name!
    store_original_name
  end

  def system_field?
    is_system_field
  end

  def user_field?
    !is_system_field
  end

  def can_be_deleted?
    !system_field?
  end

  def can_be_renamed?
    !system_field?
  end

  private def name_changed?
    @original_name != self.name
  end

  def self.find_by_name_and_resource_type(name : String, resource_type : FieldResourceType)
    filter(name: name, resource_type: resource_type.value.to_i64).first?
  end

  def self.find_by_name_and_resource_type(name : String, resource_type : Int32)
    filter(name: name, resource_type: resource_type.to_i64).first?
  end

  def delete
    raise "System fields cannot be deleted" if system_field?
    super
  end

  def save(*args, **kwargs)
    if system_field? && persisted? && name_changed?
      errors.add(:name, "cannot be changed for system fields")
      return false
    end
    super
  end

  def save!(*args, **kwargs)
    if system_field? && persisted? && name_changed?
      raise "System field name cannot be changed"
    end
    super
  end

  def localized_name_equal_to?(other : LocalizedName?) : Bool
    ln = self.localized_name
    return other.nil? && ln.nil? if other.nil?
    return false if ln.nil?
    ln == other
  end

  def localized_name_english : String?
    self.localized_name.try &.english
  end

  def localized_name_indonesian : String?
    self.localized_name.try &.indonesian
  end

  def localized_name_japanese : String?
    self.localized_name.try &.japanese
  end
end
