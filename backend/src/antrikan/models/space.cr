class Antrikan::Space < Marten::Model
  include ChangeTracker
  include SoftDeleter
  include IdConcealer

  field :id, :big_int, primary_key: true, auto: true
  field :code, :string, max_size: 5, null: false, index: true, unique: true
  field :name, :string, max_size: 255, null: false, blank: false
  field :need_manual_approval, :bool, null: false, default: true
  field :has_operating_hours, :bool, null: false, default: false
  field :created_at, :date_time, null: false, auto_now_add: true
  field :updated_at, :date_time, null: false, auto_now: true

  field :user, :many_to_one, to: Auth::User, related: :spaces

  after_initialize :generate_code

  validate :validate_name

  def self.filter_by_code(code : String)
    filter(code: code)
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
