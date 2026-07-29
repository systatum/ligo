module Antrikan
  class VoucherSerializer < ModelSerializer
    protected def fields
      record = @record.as(Voucher)

      {
        id:                          record.hashed_id,
        code:                        record.code,
        name:                        record.name,
        channel_id:                  record.channel.try(&.hashed_id),
        space_percentage_discount:   record.space_percentage_discount,
        space_fixed_discount:        record.space_fixed_discount,
        channel_percentage_discount: record.channel_percentage_discount,
        channel_fixed_discount:      record.channel_fixed_discount,
        discountable_items:          fetch_discountable_items,
        indeterminate:               record.indeterminate,
        starts_at:                   record.starts_at,
        expires_at:                  record.expires_at,
        anon_redeemable:             record.anon_redeemable,
        max_redeem_per_user:         record.max_redeem_per_user,
      }
    end

    private def fetch_discountable_items
      record = @record.as(Voucher)

      record.discountable_item_entries.map do |entry|
        DiscountableItemSerializer.soft_serialize(entry)
      end
    end
  end

  # Not a ModelSerializer subclass - DiscountableItems::Entry is a plain
  # JSON::Serializable struct, not a Marten::Model.
  class DiscountableItemSerializer
    def self.serialize(record : DiscountableItems::Entry) : String
      new(record).serialize_to_json
    end

    def self.soft_serialize(record : DiscountableItems::Entry)
      new(record).soft_serialize
    end

    def initialize(@record : DiscountableItems::Entry)
    end

    def soft_serialize
      fields
    end

    def serialize_to_json : String
      fields.to_json
    end

    private def fields
      {
        item_id:             @record.item_id,
        percentage_discount: @record.percentage_discount,
        fixed_discount:      @record.fixed_discount,
        mode:                @record.mode,
      }
    end
  end
end
