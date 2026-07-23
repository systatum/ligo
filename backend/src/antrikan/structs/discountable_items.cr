module Antrikan
  # Persisted on `Voucher#discountable_items` and copied onto `AppliedVoucher#discountable_items`.
  class DiscountableItems
    include JSON::Serializable

    # One item-specific discount rule.
    struct Entry
      include JSON::Serializable

      # An Item's `slug`, not its numeric id.
      property item_id : String
      property percentage_discount : Float64?
      property fixed_discount : Int64?

      # How this combines with the voucher's space/channel-wide rates:
      # - "override" - replaces the space/channel-wide discount entirely for this item
      # - "sum" (default) - summed with the space+channel rates, applied together in one pass
      # - "sum_separately" - space+channel discount applied first, then this discount applied
      #   again on the already-discounted remainder (compounding, not additive)
      property mode : String = "sum"
    end

    property entries : Array(Entry)

    def initialize(@entries : Array(Entry) = [] of Entry)
    end
  end
end
