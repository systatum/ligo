module Antrikan
  class Queue < Marten::Model
    include SlugGenerator
    include ChangeTracker
    include SoftDeleter
    include IdConcealer
    include QueuedTracker

    field :id, :big_int, primary_key: true, auto: true
    field :slug, :string, max_size: 8, null: false, index: true, unique: true
    field :note, :string, max_size: 255, null: true, blank: true
    field :payment_status, :int, default: PaymentStatus::UNPAID.value
    field :total_price, :big_int, default: 0 # always updated when an item is added or subtracted
    field :fully_paid_at, :date_time, null: true, blank: true
    field :updated_at, :date_time, null: false, auto_now: true

    field :channel, :many_to_one, to: Antrikan::Channel, related: :queues, null: false
    field :queuer, :many_to_one, to: Antrikan::Queuer, related: :queues, null: false
    field :handler, :many_to_one, to: Auth::User, related: :handle_queues, null: true, blank: true

    validate :validate_handler_organization

    private def generate_slug
      return unless new_record?

      year_prefix = "%02d" % (Time.utc.year % 100)
      self.slug = "#{year_prefix}#{SlugGenerator.generate(6)}"
    end

    private def validate_handler_organization
      return unless handler?

      channel_owner_organization_id = channel!.space!.owner!.organization_id
      return if handler!.organization_id == channel_owner_organization_id

      errors.add(:handler, "must be from the same organization as the channel space owner")
    end

    def sync_from_queued_items!
      # get fresh queryset from db, always
      items = Antrikan::QueuedItem.filter(queue_id: id!).to_a

      self.total_price = items.sum(0) { |item| item.unit_price! * item.quantity! }

      if items.size > 0
        all_done = items.all? { |item| item.status == QueueStatus::DONE.value }
        if all_done
          change_status!(:ready) if may_status_event?(:ready)
        elsif may_status_event?(:unready)
          change_status!(:unready)
        elsif may_status_event?(:attended)
          change_status!(:attended)
        end
      end

      save!
    end
  end
end
