module Antrikan
  # A Queue is a single person's/ticket's entry into a space, acting as a cart -
  # items are put together by the customer. Used for invoicing as well. Its items (see
  # QueuedItem) each knows their own channel, so a Queue can be for multiple channels
  # within the queue's space.
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
    # Exact BigFloat decimal string - always updated when an item is added or
    # subtracted. Not :big_int - discounts can produce fractional amounts,
    # and rounding here would misbill the customer.
    field :total_price, :string, max_size: 255, null: false, default: "0.0"
    field :fully_paid_at, :date_time, null: true, blank: true
    field :updated_at, :date_time, null: false, auto_now: true

    field :space, :many_to_one, to: Antrikan::Space, related: :queues, null: false
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

      space_owner_organization_id = space!.manager!.organization_id
      return if handler!.organization_id == space_owner_organization_id

      errors.add(:handler, "must be from the same organization as the space owner")
    end

    # Aggregate view across all this queue's payments, for a queue-level
    # dashboard/summary only - the actual refund-request validation checks
    # the specific Payment being refunded, not this aggregate.
    def amount_paid : BigFloat
      payments.filter(deleted_at: nil).sum(BigFloat.new(0)) { |p| BigFloat.new(p.amount!) }
    end

    def amount_refunded : BigFloat
      payments.filter(deleted_at: nil).sum(BigFloat.new(0)) { |p| p.amount_refunded }
    end

    def paid_balance : BigFloat
      amount_paid - amount_refunded
    end

    def sync_from_queued_items!
      # get fresh queryset from db, always
      items = Antrikan::QueuedItem.filter(queue_id: id!).to_a

      self.total_price = items.sum(BigFloat.new(0)) { |item| item.discounted_line_total }.to_s
      previous_status = status

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
      publish_queue_updated(items) if status != previous_status
    end

    # Fans out to every channel represented among this queue's items, so each
    # channel's monitor sees updates for queues with items assigned to it.
    private def publish_queue_updated(items : Array(Antrikan::QueuedItem))
      channels = items.map(&.channel!).uniq(&.id)
      channels.each do |channel|
        ChannelEventPublisher.publish(channel,
          type: "queue_updated",
          key: "queue",
          value: QueueSerializer.soft_serialize(self))
      end
    end
  end
end
