module Antrikan
  class Voucher < Marten::Model
    include ChangeTracker
    include SoftDeleter
    include IdConcealer

    field :id, :big_int, primary_key: true, auto: true
    field :code, :string, max_size: 255, null: false, index: true, unique: true
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
    # true (default): usable forever, `starts_at`/`expires_at` are ignored.
    # false: only usable between `starts_at` and `expires_at`.
    field :indeterminate, :bool, null: false, default: true
    field :starts_at, :date_time, null: true, blank: true
    field :expires_at, :date_time, null: true, blank: true
    # true (default): redeemable without a registered/signed-up user - we won't
    # know who redeemed it. false: redeemer must be a registered user.
    field :anon_redeemable, :bool, null: false, default: true
    # Max times the same registered user can redeem this voucher. -1 (default):
    # unlimited. Only enforceable when `anon_redeemable` is false - the redeemer
    # otherwise isn't tracked.
    field :max_redeem_per_user, :int, null: false, default: -1
    field :created_at, :date_time, null: false, auto_now_add: true
    field :updated_at, :date_time, null: false, auto_now: true

    field :space, :many_to_one, to: Antrikan::Space, related: :vouchers
    # The single channel the channel-wide rates above target.
    field :channel, :many_to_one, to: Antrikan::Channel, related: :vouchers, null: true, blank: true

    after_initialize :generate_code

    validate :validate_active_window

    # TODO: usage-limit/redemption tracking

    def self.find_by_code(code : String, space_id : Int32 | Int64) : Voucher?
      filter(code: code, space_id: space_id).first?
    end

    def discountable_item_entries : Array(DiscountableItems::Entry)
      discountable_items.try(&.entries) || [] of DiscountableItems::Entry
    end

    def currently_usable?(time : Time = Time.utc) : Bool
      return true if indeterminate!
      return false if starts_at.nil? || expires_at.nil?

      time >= starts_at! && time <= expires_at!
    end

    private def generate_code
      return unless new_record?
      return unless code.nil?

      self.code = SlugGenerator.generate(size: 8)
    end

    private def validate_active_window
      return if indeterminate!

      errors.add(:starts_at, "must be set when indeterminate is false") if starts_at.nil?
      errors.add(:expires_at, "must be set when indeterminate is false") if expires_at.nil?
      return if starts_at.nil? || expires_at.nil?

      if starts_at! >= expires_at!
        errors.add(:expires_at, "must be after starts_at")
      end
    end
  end
end
