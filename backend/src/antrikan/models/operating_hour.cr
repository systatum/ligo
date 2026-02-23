class Antrikan::OperatingHour < Marten::Model
  include ChangeTracker
  include SoftDeleter
  include IdConcealer

  # Days of the week: 0 = Monday, 1 = Tuesday, ..., 6 = Sunday
  enum Day
    MONDAY    = 0
    TUESDAY   = 1
    WEDNESDAY = 2
    THURSDAY  = 3
    FRIDAY    = 4
    SATURDAY  = 5
    SUNDAY    = 6
  end

  field :id, :big_int, primary_key: true, auto: true
  field :day, :int, null: false
  field :open_time, :duration, null: false
  field :close_time, :duration, null: false
  field :created_at, :date_time, null: false, auto_now_add: true
  field :updated_at, :date_time, null: false, auto_now: true

  field :space, :many_to_one, to: Antrikan::Space, related: :operating_hours

  validate :validate_day_range
  validate :validate_time_range
  validate :validate_uniqueness_per_day

  # Check if a given time falls within operating hours
  def open_at?(time : Time) : Bool
    return false unless open_time? && close_time?

    current = Time::Span.new(hours: time.hour, minutes: time.minute, seconds: time.second, nanoseconds: time.nanosecond)
    current >= open_time! && current < close_time!
  end

  private def validate_day_range
    return unless day?

    unless day! >= 0 && day! <= 6
      errors.add(:day, "Day must be between 0 (Monday) and 6 (Sunday)")
    end
  end

  private def validate_time_range
    return unless open_time? && close_time?

    if open_time! >= close_time!
      errors.add(:close_time, "must be after open time")
    end
  end

  private def validate_uniqueness_per_day
    # Use nil check instead of day? because day?/space_id? return false for 0 values
    day_value = @day
    return if day_value.nil?

    # Get space_id from either direct assignment or relationship
    sid = space_id? ? space_id! : (space? ? space!.id : nil)
    return unless sid

    existing = Antrikan::OperatingHour.filter(
      space_id: sid,
      day: day_value,
      deleted_at: nil
    )

    # Exclude self when updating
    existing = existing.exclude(id: id!) if persisted?

    if existing.exists?
      errors.add(:day, "Operating hours for this day already exist for this space")
    end
  end
end
