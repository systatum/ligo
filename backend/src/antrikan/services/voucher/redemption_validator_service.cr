module Antrikan
  class Voucher::RedemptionValidatorService < BaseService(Voucher)
    def initialize(@voucher : Voucher, @queue : Queue)
    end

    def run : ServiceResult(Voucher)
      return failure(:voucher_code, ErrorCode::VOUCHER_INACTIVE) unless @voucher.currently_usable?

      user = @queue.queuer!.user
      if !@voucher.anon_redeemable! && user.nil?
        return failure(:voucher_code, ErrorCode::VOUCHER_NOT_ANON_REDEEMABLE)
      end
      return success(@voucher) if user.nil? || @voucher.max_redeem_per_user! == -1

      redeemed_count = AppliedVoucher.filter(voucher_id: @voucher.id!, redeemer_id: user.id!).count
      if redeemed_count >= @voucher.max_redeem_per_user!
        return failure(:voucher_code, ErrorCode::VOUCHER_REDEEMER_MAXED_QUOTA)
      end

      success(@voucher)
    end
  end
end
