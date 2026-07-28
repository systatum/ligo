module Antrikan
  class QueuedItem < Marten::Model
    include SlugGenerator
    include ChangeTracker
    include SoftDeleter
    include QueuedTracker

    field :id, :uuid, primary_key: true
    field :slug, :string, max_size: 8, null: false, index: true, unique: true
    field :note, :string, max_size: 255, null: true, blank: true
    # Reason given when the item is CANCELED; ignored otherwise
    field :cancel_note, :string, max_size: 255, null: true, blank: true
    field :unit_price, :big_int, null: false, default: 0
    field :quantity, :int, null: false, default: 1
    # The logical ordering of the item in a queue.
    # To be used for front-end purposes
    field :rank, :int, null: true, blank: true
    # The timestamp of the last time the order was changed
    field :reranked_at, :date_time, null: true, blank: true
    field :applied_voucher_ids, :json, null: true, blank: true, serializable: AppliedVoucherIds
    field :updated_at, :date_time, null: false, auto_now: true

    field :queue, :many_to_one, to: Antrikan::Queue, related: :queued_items, null: false
    field :channel, :many_to_one, to: Antrikan::Channel, related: :queued_items, null: false
    field :item, :many_to_one, to: Antrikan::Item, related: :queued_items, null: false
    field :handler, :many_to_one, to: Auth::User, related: :handle_queued_items, null: true, blank: true

    after_save :sync_parent_queue

    validate :validate_item

    private def sync_parent_queue
      queue!.sync_from_queued_items!
    end

    private def validate_item
      return if item!.channel!.space_id == queue!.space_id
      errors.add(:item_id, "Item must belong to the same space as the queue")
    end

    # unit_price * quantity, with every stacked AppliedVoucher applied in
    # attachment order (each voucher's result becomes the next voucher's base).
    # BigFloat to avoid compounding rounding error across chained discounts -
    # round only once, at the point this gets written into a :big_int column.
    def discounted_line_total : BigFloat
      base = BigFloat.new(unit_price! * quantity!)
      applied_vouchers.reduce(base) { |running, voucher| apply_voucher(running, voucher) }
    end

    # Every AppliedVoucher discounting this item, in the order they were attached.
    def applied_vouchers : Array(AppliedVoucher)
      ids = applied_voucher_ids.try(&.ids) || [] of Int64
      return [] of AppliedVoucher if ids.empty?

      by_id = AppliedVoucher.filter(id__in: ids).each_with_object({} of Int64 => AppliedVoucher) do |av, h|
        h[av.id!.to_i64] = av
      end
      ids.compact_map { |id| by_id[id]? }
    end

    def add_applied_voucher!(applied_voucher : AppliedVoucher)
      current = applied_voucher_ids.try(&.ids) || [] of Int64
      self.applied_voucher_ids = AppliedVoucherIds.new(ids: current + [applied_voucher.id!.to_i64])
      save!
    end

    private def apply_voucher(base : BigFloat, voucher : AppliedVoucher) : BigFloat
      item_rate = voucher.discountable_item_entries.find { |e| e.item_id == item!.slug! }
      channel_eligible = !voucher.channel_id.nil? && voucher.channel_id == channel_id
      space_pct = voucher.space_percentage_discount || 0.0
      space_fixed = (voucher.space_fixed_discount || 0).to_i64
      channel_pct = channel_eligible ? (voucher.channel_percentage_discount || 0.0) : 0.0
      channel_fixed = channel_eligible ? (voucher.channel_fixed_discount || 0).to_i64 : 0_i64
      item_pct = item_rate.try(&.percentage_discount) || 0.0
      item_fixed = item_rate.try(&.fixed_discount) || 0_i64

      case item_rate.try(&.mode)
      when "override"
        apply_rate(base, item_pct, item_fixed)
      when "sum_separately"
        after_scope = apply_rate(base, space_pct + channel_pct, space_fixed + channel_fixed)
        apply_rate(after_scope, item_pct, item_fixed)
      else
        apply_rate(base, space_pct + channel_pct + item_pct, space_fixed + channel_fixed + item_fixed)
      end
    end

    # base: the amount being discounted (e.g. the line total so far)
    # percentage: a whole number, 10 means 10% off (not 0.10)
    # fixed: a flat amount taken off after the percentage is applied
    # Example: base: 100, percentage: 10, fixed: 5 -> 100 * (1 - 10/100) - 5 = 85.
    private def apply_rate(base : BigFloat, percentage : Float64, fixed : Int64) : BigFloat
      discounted = base * (BigFloat.new(1) - BigFloat.new(percentage) / BigFloat.new(100)) - BigFloat.new(fixed)
      discounted.negative? ? BigFloat.new(0) : discounted
    end
  end
end
