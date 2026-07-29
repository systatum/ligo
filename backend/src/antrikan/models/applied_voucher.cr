module Antrikan
  # An immutable, append-only snapshot of a Voucher's rates at the moment it was
  # attached to a Queue - later edits to the live Voucher never change this.
  class AppliedVoucher < Marten::Model
    field :id, :big_int, primary_key: true, auto: true
    field :code, :string, max_size: 255, null: false
    field :name, :string, max_size: 255, null: true, blank: true
    # Percentage off applied space-wide, e.g. 10 means 10% off.
    field :space_percentage_discount, :float, null: true, blank: true
    # Flat amount off applied space-wide.
    field :space_fixed_discount, :big_int, null: true, blank: true
    # Percentage off applied only to items in `channel`.
    field :channel_percentage_discount, :float, null: true, blank: true
    # Flat amount off applied only to items in `channel`.
    field :channel_fixed_discount, :big_int, null: true, blank: true
    field :discountable_items, :json, null: true, blank: true, serializable: DiscountableItems
    field :indeterminate, :bool, null: false, default: true
    field :starts_at, :date_time, null: true, blank: true
    field :expires_at, :date_time, null: true, blank: true
    field :anon_redeemable, :bool, null: false, default: true
    field :max_redeem_per_user, :int, null: false, default: -1
    field :created_at, :date_time, null: false, auto_now_add: true

    field :queue, :many_to_one, to: Antrikan::Queue, related: :applied_vouchers, null: false
    field :voucher, :many_to_one, to: Antrikan::Voucher, related: :applied_vouchers, null: false
    # The single channel the channel-wide rates above target.
    field :channel, :many_to_one, to: Antrikan::Channel, related: :applied_vouchers, null: true, blank: true
    # Who redeemed this - only set when the voucher isn't anonymously redeemable
    # (that's the only case where we actually need to know who redeemed it).
    field :redeemer, :many_to_one, to: Auth::User, related: :redeemed_vouchers, null: true, blank: true

    def self.snapshot(voucher : Voucher, queue : Queue) : AppliedVoucher
      applied = new
      applied.queue = queue
      applied.voucher = voucher
      applied.code = voucher.code!
      applied.name = voucher.name
      applied.channel = voucher.channel
      applied.space_percentage_discount = voucher.space_percentage_discount
      applied.space_fixed_discount = voucher.space_fixed_discount
      applied.channel_percentage_discount = voucher.channel_percentage_discount
      applied.channel_fixed_discount = voucher.channel_fixed_discount
      applied.discountable_items = voucher.discountable_items
      applied.indeterminate = voucher.indeterminate!
      applied.starts_at = voucher.starts_at
      applied.expires_at = voucher.expires_at
      applied.anon_redeemable = voucher.anon_redeemable!
      applied.max_redeem_per_user = voucher.max_redeem_per_user!
      applied.redeemer = queue.queuer!.user unless voucher.anon_redeemable!
      applied
    end

    def discountable_item_entries : Array(DiscountableItems::Entry)
      discountable_items.try(&.entries) || [] of DiscountableItems::Entry
    end

    def to_voucher : Voucher
      v = Voucher.new
      v.code = code
      v.name = name
      v.channel = channel
      v.space_percentage_discount = space_percentage_discount
      v.space_fixed_discount = space_fixed_discount
      v.channel_percentage_discount = channel_percentage_discount
      v.channel_fixed_discount = channel_fixed_discount
      v.discountable_items = discountable_items
      v.indeterminate = indeterminate!
      v.starts_at = starts_at
      v.expires_at = expires_at
      v.anon_redeemable = anon_redeemable!
      v.max_redeem_per_user = max_redeem_per_user!
      v
    end
  end
end
