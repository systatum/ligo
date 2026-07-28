module Antrikan
  class Payment::CreatorService < BaseService(Payment)
    def initialize(@queue : Queue, @data : Marten::HTTP::Params::Data, @recorded_by : Auth::User)
    end

    def run : ServiceResult(Payment)
      return failure(schema.errors) unless schema.valid?

      begin
        payment = Payment.new
        payment.queue = @queue
        payment.recorded_by = @recorded_by
        payment.amount = schema.amount!
        payment.method = schema.method if schema.method?
        payment.note = schema.note if schema.note?
        payment.save!

        success(payment)
      rescue ex : Marten::DB::Errors::InvalidRecord
        failure(ex.record.errors)
      end
    end

    private def schema
      @schema ||= PaymentSchema.new(@data)
    end
  end
end
