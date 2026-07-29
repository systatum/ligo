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

  # Exactly one of space/channel/item is set - see validate_exactly_one_owner.
  field :space, :many_to_one, to: Antrikan::Space, related: :operating_hours, null: true, blank: true
  field :channel, :many_to_one, to: Antrikan::Channel, related: :operating_hours, null: true, blank: true
  field :item, :many_to_one, to: Antrikan::Item, related: :operating_hours, null: true, blank: true

  validate :validate_exactly_one_owner
  validate :validate_day_range
  validate :validate_time_range
  validate :validate_uniqueness_per_day

  # Check if a given time falls within operating hours
  def open_at?(time : Time) : Bool
    return false unless open_time? && close_time?

    current = Time::Span.new(hours: time.hour, minutes: time.minute, seconds: time.second, nanoseconds: time.nanosecond)
    current >= open_time! && current < close_time!
  end

  private def resolved_space_id
    space_id? ? space_id! : nil
  end

  private def resolved_channel_id
    channel_id? ? channel_id! : nil
  end

  private def resolved_item_id
    item_id? ? item_id! : nil
  end

  private def validate_exactly_one_owner
    owner_count = [resolved_space_id, resolved_channel_id, resolved_item_id].count { |id| !id.nil? }

    if owner_count != 1
      errors.add(:base, "Exactly one of space, channel, or item must be set")
    end
  end

  private def validate_day_range
    # Marten's day? accessor treats 0 (Monday) as absent, so check @day directly.
    day_value = @day
    return if day_value.nil?

    unless day_value >= 0 && day_value <= 6
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
    # Same day? gotcha as validate_day_range - use @day directly.
    day_value = @day
    return if day_value.nil?

    scope = uniqueness_scope(day_value)
    return unless scope

    scope = scope.exclude(id: id!) if persisted?

    if scope.exists?
      errors.add(:day, "Operating hours for this day already exist for this owner")
    end
  end

  private def uniqueness_scope(day_value)
    if (sid = resolved_space_id)
      return Antrikan::OperatingHour.filter(space_id: sid, day: day_value, deleted_at: nil)
    end

    if (cid = resolved_channel_id)
      return Antrikan::OperatingHour.filter(channel_id: cid, day: day_value, deleted_at: nil)
    end

    if (iid = resolved_item_id)
      return Antrikan::OperatingHour.filter(item_id: iid, day: day_value, deleted_at: nil)
    end

    nil
  end
end
