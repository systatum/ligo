class FieldDefinition < Marten::Model
  include IdConcealer
  include SoftDeleter

  field :id, :big_int, primary_key: true, auto: true
  field :name, :string, max_size: 255, null: false, blank: false
  field :localized_name, :json, null: true, blank: true, serializer: LocalizedName
  field :resource_type, :enum, values: FieldResourceType, null: false
  field :data_type, :enum, values: FieldDataType, null: false
  field :is_system_field, :bool, null: false, default: false
  field :nullable, :bool, null: false, default: true
  field :uniqueness, :enum, values: FieldUniqueness, null: false, default: FieldUniqueness::UNIQUELESS
  field :created_at, :date_time, null: false, auto_now_add: true
  field :updated_at, :date_time, null: false, auto_now: true

  validate :validate_name_uniqueness_per_resource_type
  validate :validate_system_field_constraints

  scope :system_fields { filter(is_system_field: true) }
  scope :user_fields { filter(is_system_field: false) }
  scope :for_resource_type { |resource_type| filter(resource_type: resource_type) }

  after_initialize :store_original_name

  private def validate_name_uniqueness_per_resource_type
    existing = self.class.filter(name: name, resource_type: resource_type)
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
    filter(name: name, resource_type: resource_type).first?
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
end
