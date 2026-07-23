module Antrikan
  class Voucher::RedeemerService < BaseService(AppliedVoucher)
    def initialize(@queue : Queue, @code : String)
    end

    def run : ServiceResult(AppliedVoucher)
      voucher = Voucher.find_by_code(@code, @queue.channel!.space_id!.as(Int32 | Int64))
      return failure(:voucher_code, ErrorCode::VOUCHER_NOT_FOUND) if voucher.nil?

      result = Voucher::RedemptionValidatorService.new(voucher, @queue).run
      return failure(result.errors) unless result.success?

      applied = AppliedVoucher.snapshot(voucher, @queue)
      applied.save!

      success(applied)
    end
  end
end
