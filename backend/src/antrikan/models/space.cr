class Antrikan::Space < Marten::Model
  include ChangeTracker
  include SoftDeleter
  include IdConcealer

  field :id, :big_int, primary_key: true, auto: true
  field :code, :string, max_size: 5, null: false, index: true, unique: true
  field :name, :string, max_size: 255, null: false, blank: false
  field :description, :text, null: true, blank: true
  field :need_manual_approval, :bool, null: false, default: true
  field :has_operating_hours, :bool, null: false, default: false
  field :require_registered_queuer, :bool, null: false, default: false
  # If true, a SpaceReview may be created without an authenticated reviewer.
  field :allow_anonymous_reviewer, :bool, null: false, default: false
  field :logo_file_id, :uuid, null: true, blank: true
  field :carousel_image_ids, :json, null: true, blank: true, serializable: UploadedFileIds
  field :address, :string, max_size: 255, null: true, blank: true
  # An entry id in data/countries/<country_code>_<ISO 3166-1 alpha-3>.json
  # (e.g. data/countries/100_IDN.json) - see CountryCityDirectory.
  field :address_city_code, :int, null: true, blank: true
  field :address_postal_code, :string, max_size: 20, null: true, blank: true
  field :latitude, :float, null: true, blank: true
  field :longitude, :float, null: true, blank: true
  field :phone, :string, max_size: 20, null: true, blank: true
  field :email, :string, max_size: 255, null: true, blank: true
  field :created_at, :date_time, null: false, auto_now_add: true
  field :updated_at, :date_time, null: false, auto_now: true

  field :manager, :many_to_one, to: Auth::User, related: :spaces
  field :owner, :many_to_one, to: Antrikan::Business, related: :spaces
  field :members, :many_to_many, to: Auth::User, related: :joined_spaces

  after_initialize :generate_code

  validate :validate_name
  validate :validate_address_city_code

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

  # Broader than owned_by? - also true for any admin-level staff (see
  # Auth::Role.admin?) from the same organization, not just the owner tier.
  # Used for Payment/Refund, which are ordinary staff actions, not owner-only ones.
  def staffed_by?(user : Auth::User) : Bool
    return true if owned_by?(user)

    Auth::Role.admin?(user) && user.organization_id == manager!.organization_id
  end

  def average_rating : Float64
    reviews.filter(deleted_at: nil).average(:rating) || 0.0
  end

  def review_count : Int32 | Int64
    reviews.filter(deleted_at: nil).count
  end

  def operating_hour_for(day : Int32) : Antrikan::OperatingHour?
    Antrikan::OperatingHour.filter(space_id: id!, day: day, deleted_at: nil).first?
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

  private def validate_address_city_code
    code = address_city_code
    return if code.nil?

    unless CountryCityDirectory.valid_city_code?(code)
      errors.add(:address_city_code, "does not match a known city entry in data/countries")
    end
  end
end
