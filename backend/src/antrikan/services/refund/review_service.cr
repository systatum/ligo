module Antrikan
  class Refund::ReviewService < BaseService(Refund)
    def initialize(@refund : Refund, @accepted : Bool, @reviewer : Auth::User, @data : Marten::HTTP::Params::Data)
    end

    def run : ServiceResult(Refund)
      return failure(schema.errors) unless schema.valid?
      return failure(:status, ErrorCode::REFUND_ALREADY_REVIEWED) unless @refund.status! == RefundStatus::PENDING.value

      if @accepted && !within_remaining_balance?
        return failure(:amount, ErrorCode::REFUND_NEGATIVE_BALANCE)
      end

      begin
        @refund.status = @accepted ? RefundStatus::ACCEPTED.value : RefundStatus::REJECTED.value
        @refund.reviewed_by = @reviewer
        @refund.reviewed_at = Time.utc
        @refund.review_note = schema.review_note if schema.review_note?
        @refund.save!

        success(@refund)
      rescue ex : Marten::DB::Errors::InvalidRecord
        failure(ex.record.errors)
      end
    end

    # Re-checked here, not just at request time - other refunds against the
    # same payment may have been accepted in between request and review.
    private def within_remaining_balance? : Bool
      return true if @refund.forceful!

      @refund.payment!.remaining_refundable_amount - BigFloat.new(@refund.amount!) >= BigFloat.new(0)
    end

    private def schema
      @schema ||= RefundReviewSchema.new(@data)
    end
  end
end
