module Antrikan
  class Voucher::UpserterService < BaseService(Voucher)
    def initialize(@voucher : Voucher, @data : Marten::HTTP::Params::Data)
    end

    def run : ServiceResult(Voucher)
      return failure(schema.errors) unless schema.valid?

      begin
        @voucher.channel = Channel.get_by_hashed_id!(schema.channel_id!) if schema.channel_id?
        @voucher.code = schema.code! if schema.code?
        @voucher.name = schema.name if schema.name?
        @voucher.space_percentage_discount = schema.space_percentage_discount if schema.space_percentage_discount?
        @voucher.space_fixed_discount = schema.space_fixed_discount if schema.space_fixed_discount?
        if schema.channel_percentage_discount?
          @voucher.channel_percentage_discount = schema.channel_percentage_discount
        end
        @voucher.channel_fixed_discount = schema.channel_fixed_discount if schema.channel_fixed_discount?
        if schema.discountable_items?
          @voucher.discountable_items = DiscountableItems.new(entries: discountable_item_entries)
        end
        # not `schema.indeterminate?` - Marten's Bool schema field treats `false`
        # itself as "empty", so that presence check can never see an explicit false.
        @voucher.indeterminate = schema.indeterminate if @data.has_key?("indeterminate")
        @voucher.starts_at = schema.starts_at if schema.starts_at?
        @voucher.expires_at = schema.expires_at if schema.expires_at?
        @voucher.anon_redeemable = schema.anon_redeemable if @data.has_key?("anon_redeemable")
        @voucher.max_redeem_per_user = schema.max_redeem_per_user if schema.max_redeem_per_user?
        @voucher.save!

        success(@voucher)
      rescue ex : Marten::DB::Errors::InvalidRecord
        failure(ex.record.errors)
      end
    end

    private def discountable_item_entries : Array(DiscountableItems::Entry)
      schema.discountable_items!.map(&.as(DiscountableItems::Entry))
    end

    private def schema
      @schema ||= VoucherSchema.new(JsonArrayMapper.map(@data, "discountable_items"))
    end
  end
end
