module Antrikan
  module VoucherHelper
    @voucher : Voucher?
    @schema : VoucherSchema?

    private def voucher
      @voucher ||= Voucher
        .filter_by_hashed_id(params["voucher_hashed_id"].to_s)
        .get!
    end

    private def voucher_including_deleted
      @voucher ||= Voucher
        .filter_by_hashed_id(params["voucher_hashed_id"].to_s, unscoped: true)
        .get!
    end

    private def authorized_for_voucher?
      voucher.space!.owned_by?(current_user!)
    end

    private def authorized_for_voucher_including_deleted?
      voucher_including_deleted.space!.owned_by?(current_user!)
    end

    private def schema
      @schema ||= VoucherSchema.new(JsonArrayMapper.map(request.data, "discountable_items"))
    end
  end
end
