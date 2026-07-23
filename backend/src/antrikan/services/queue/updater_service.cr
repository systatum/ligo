module Antrikan
  class Queue::UpdaterService < BaseService(Queue)
    def initialize(@queue : Queue, @data : Marten::HTTP::Params::Data, @current_user : Auth::User? = nil)
    end

    def run : ServiceResult(Queue)
      return failure(schema.errors) unless schema.valid?
      return failure(:voucher_code, "not authorized") if schema.voucher_code? && !staff?

      begin
        was_unpaid = @queue.payment_status! == PaymentStatus::UNPAID.value

        Queue.transaction do
          update_fields
          attach_voucher!

          if was_unpaid && @queue.payment_status! != PaymentStatus::UNPAID.value
            PayTimeDiscountApplierService.new(@queue).run
          end
        end

        success(@queue)
      rescue ex : TransactionError
        failure(ex.errors)
      rescue ex : AASM::AASMException
        failure(:status, ex.message || "Invalid status transition")
      rescue ex : Marten::DB::Errors::InvalidRecord
        failure(ex.record.errors)
      end
    end

    private def staff? : Bool
      user = @current_user
      return false if user.nil?
      @queue.channel!.space!.owned_by?(user)
    end

    private def attach_voucher!
      return unless schema.voucher_code?

      result = Voucher::RedeemerService.new(@queue, schema.voucher_code!).run
      raise TransactionError.new(result.errors) unless result.success?
    end

    private def update_fields
      handler = schema.handler_id? ? Auth::User.get_by_hashed_id!(schema.handler_id!) : nil

      @queue.handler = handler if schema.handler_id?
      @queue.note = schema.note if schema.note?
      @queue.payment_status = schema.payment_status!.value if schema.payment_status?
      @queue.fully_paid_at = schema.fully_paid_at if schema.fully_paid_at?
      @queue.change_status!(schema.status!.to_state) if schema.status?

      @queue.save!
    end

    private def schema
      @schema ||= QueueUpdateSchema.new(@data)
    end
  end
end
