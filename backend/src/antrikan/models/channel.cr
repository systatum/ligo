module Antrikan
  class Channel < Marten::Model
    include ChangeTracker
    include SoftDeleter
    include IdConcealer

    field :id, :big_int, primary_key: true, auto: true
    field :space, :many_to_one, to: Antrikan::Space, related: :channels
    # One level deep only, e.g. a doctor channel under a specialty channel.
    field :parent_channel, :many_to_one, to: Antrikan::Channel, related: :sub_channels, null: true, blank: true
    field :name, :string, max_size: 255, null: false, blank: false
    field :logo_file_id, :uuid, null: true, blank: true
    field :description, :text, null: true, blank: true
    # Latest QueuedItem state at/before which cancellation (deletion) is still allowed
    field :predeletable_state, :int, null: false, default: QueueStatus::ATTENDED.value
    # If true, reject adding a QueuedItem whose item is outside its effective operating hours.
    field :enforce_operating_hours, :bool, null: false, default: false
    # Max non-canceled QueuedItems of this channel allowed per queue. -1 (default): unlimited.
    field :max_item_piece, :int, null: false, default: -1
    field :created_at, :date_time, null: false, auto_now_add: true
    field :updated_at, :date_time, null: false, auto_now: true

    validate :validate_parent_channel

    def operating_hour_for(day : Int32) : Antrikan::OperatingHour?
      Antrikan::OperatingHour.filter(channel_id: id!, day: day, deleted_at: nil).first? ||
        parent_channel.try(&.operating_hour_for(day)) || space!.operating_hour_for(day)
    end

    def open_at?(time : Time = Time.utc) : Bool
      hour = operating_hour_for(time.day_of_week.value - 1)
      hour.nil? || hour.open_at?(time)
    end

    private def validate_parent_channel
      parent = parent_channel
      return if parent.nil?

      if persisted? && parent.id == id
        errors.add(:parent_channel, "cannot be its own parent")
        return
      end

      unless parent.space_id == space_id
        errors.add(:parent_channel, "must belong to the same space")
        return
      end

      unless parent.parent_channel_id.nil?
        errors.add(:parent_channel, "cannot itself be a sub-channel (only one level of nesting is allowed)")
      end
    end
  end
end
