module Antrikan
  class VoucherSchema < BaseSchema
    VALID_MODES = %w(override sum sum_separately)

    # Redemption code; auto-generated if omitted.
    field :code, :string, max_size: 255, required: false, strip: true
    field :name, :string, max_size: 255, required: false, strip: true
    # The single channel the channel-wide rates below target.
    field :channel_id, :string, required: false, strip: true
    # Percentage off applied space-wide, e.g. 10 means 10% off.
    field :space_percentage_discount, :float, required: false
    # Flat amount off applied space-wide.
    field :space_fixed_discount, :int, required: false
    # Percentage off applied only to items in `channel_id`.
    field :channel_percentage_discount, :float, required: false
    # Flat amount off applied only to items in `channel_id`.
    field :channel_fixed_discount, :int, required: false
    # Per-item discount rules - see DiscountableItems::Entry for how each one
    # combines with the space/channel-wide rates above.
    field :discountable_items, :array, required: false, of: :json, serializable: DiscountableItems::Entry
    # true (default): usable forever. false: only usable between starts_at/expires_at.
    field :indeterminate, :bool, required: false
    field :starts_at, :date_time, required: false
    field :expires_at, :date_time, required: false
    # true (default): redeemable without a registered/signed-up user.
    field :anon_redeemable, :bool, required: false
    # Max times the same user can redeem this voucher. -1 (default): unlimited.
    field :max_redeem_per_user, :int, required: false

    validate :validate_discountable_item_modes

    private def validate_discountable_item_modes
      return unless discountable_items?

      discountable_items!.each do |entry|
        next if VALID_MODES.includes?(entry.as(DiscountableItems::Entry).mode)
        errors.add(:discountable_items, "mode must be one of #{VALID_MODES.join(", ")}")
      end
    end
  end
end
