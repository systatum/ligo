class FieldDefinition < Marten::Model
  include IdConcealer
  include SoftDeleter

  alias FDC = FieldDefinitionConcerns
  extend FDC::MetafieldManipulator
  extend FDC::Finder
  include FDC::Coercer

  field :id, :big_int, primary_key: true, auto: true
  field :name, :string, max_size: 255, null: false, blank: false
  field :localized_name, :json, null: true, blank: true, serializable: LocalizedName
  field :metadata, :json, null: true, blank: true
  field :resource_type, :int, null: false, index: true
  field :data_type, :int, null: false
  field :is_system_field, :bool, null: false, default: false
  field :nullable, :bool, null: false, default: true
  field :uniqueness, :enum, values: FieldUniqueness, null: false, default: FieldUniqueness::UNIQUELESS
  field :created_at, :date_time, null: false, auto_now_add: true
  field :updated_at, :date_time, null: false, auto_now: true

  def initialize(
    *,
    name : String? = nil,
    resource_type : FieldResourceType,
    data_type : FieldDataType? = nil,
    nullable : Bool? = nil,
    uniqueness : FieldUniqueness? = nil,
    is_system_field : Bool? = nil,
    localized_name : LocalizedName? = nil,
    metadata : JSON::Any? = nil,
  )
    super(name: name, resource_type: resource_type.value.to_i64)
    self.data_type = data_type if data_type
    self.nullable = nullable if !nullable.nil?
    self.uniqueness = uniqueness if uniqueness
    self.is_system_field = is_system_field if !is_system_field.nil?
    self.localized_name = localized_name if localized_name
    self.metadata = metadata if metadata
  end

  def initialize(
    *,
    name : String? = nil,
    resource_type : Int64? = nil,
    data_type : Int64? = nil,
    nullable : Bool? = nil,
    uniqueness : FieldUniqueness? = nil,
    is_system_field : Bool? = nil,
    localized_name : LocalizedName? = nil,
    metadata : JSON::Any? = nil,
  )
    super(name: name, resource_type: resource_type)
    self.data_type = data_type if data_type
    self.nullable = nullable if !nullable.nil?
    self.uniqueness = uniqueness if uniqueness
    self.is_system_field = is_system_field if !is_system_field.nil?
    self.localized_name = localized_name if localized_name
    self.metadata = metadata if metadata
  end

  validate :validate_name_uniqueness_per_resource_type
  validate :validate_system_field_constraints

  scope :system_fields { filter(is_system_field: true) }
  scope :user_fields { filter(is_system_field: false) }

  after_initialize :store_original_name
  after_initialize :coerce_resource_type!
  after_initialize :coerce_data_type!

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

  def delete
    raise "System fields cannot be deleted" if system_field?
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
