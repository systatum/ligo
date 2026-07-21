class Antrikan::Space < Marten::Model
  include ChangeTracker
  include SoftDeleter
  include IdConcealer

  field :id, :big_int, primary_key: true, auto: true
  field :code, :string, max_size: 5, null: false, index: true, unique: true
  field :name, :string, max_size: 255, null: false, blank: false
  field :need_manual_approval, :bool, null: false, default: true
  field :has_operating_hours, :bool, null: false, default: false
  field :require_registered_queuer, :bool, null: false, default: false
  field :logo_file_id, :uuid, null: true, blank: true
  field :carousel_image_ids, :json, null: true, blank: true, serializable: CarouselImageIds
  field :address, :text, null: true, blank: true
  field :phone, :string, max_size: 20, null: true, blank: true
  field :email, :string, max_size: 255, null: true, blank: true
  field :created_at, :date_time, null: false, auto_now_add: true
  field :updated_at, :date_time, null: false, auto_now: true

  field :manager, :many_to_one, to: Auth::User, related: :spaces
  field :owner, :many_to_one, to: Antrikan::Business, related: :spaces
  field :members, :many_to_many, to: Auth::User, related: :joined_spaces

  after_initialize :generate_code

  validate :validate_name

  def self.filter_by_code(code : String)
    filter(code: code)
  end

  # True for the space's manager, the owner of its business, or for any
  # Auth::Role::OWNER-level user from the same organization as the manager.
  def owned_by?(user : Auth::User) : Bool
    return true if manager == user
    return true if owner!.owner == user
    Auth::Role.owner?(user) && user.organization_id == manager!.organization_id
  end

  def average_rating : Float64
    reviews.filter(deleted_at: nil).average(:rating) || 0.0
  end

  def review_count : Int32 | Int64
    reviews.filter(deleted_at: nil).count
  end

  private def generate_code
    return unless new_record?
    return unless code.nil?

    self.code = SlugGenerator.generate(size: 5)
  end

  private def validate_name
    if name.nil? || name!.blank?
      errors.add(:name, "Name cannot be blank")
    elsif name!.size > 255
      errors.add(:name, "Name cannot exceed 255 characters")
    end
  end
end
