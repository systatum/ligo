module Antrikan
  class Refund::RequestService < BaseService(Refund)
    def initialize(@payment : Payment, @data : Marten::HTTP::Params::Data, @requested_by : Auth::User? = nil)
    end

    def run : ServiceResult(Refund)
      return failure(schema.errors) unless schema.valid?

      unless @payment.queue!.payment_status! != PaymentStatus::UNPAID.value
        return failure(:payment, ErrorCode::PAYMENT_UNPAID)
      end

      amount = BigFloat.new(schema.amount!)
      forceful = @data.has_key?("forceful") ? schema.forceful! : false
      projected_balance = @payment.remaining_refundable_amount - amount

      if projected_balance < BigFloat.new(0) && !forceful
        return failure(:amount, ErrorCode::REFUND_NEGATIVE_BALANCE)
      end

      begin
        image_result = CarouselImagesResolverService.new(schema.images || [] of (JSON::Any | JSON::Serializable | Nil)).run
        return failure(image_result.errors) unless image_result.success?

        refund = Refund.new
        refund.id = UUID.random
        refund.payment = @payment
        refund.amount = schema.amount!
        refund.reason = schema.reason if schema.reason?
        refund.forceful = forceful
        refund.requested_by = @requested_by
        refund.image_ids = UploadedFileIds.new(ids: image_result.data.not_nil!)
        refund.save!

        success(refund)
      rescue ex : Marten::DB::Errors::InvalidRecord
        failure(ex.record.errors)
      end
    end

    private def schema
      @schema ||= RefundSchema.new(@data)
    end
  end
end
