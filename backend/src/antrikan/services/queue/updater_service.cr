module Antrikan
  class Queue::UpdaterService < BaseService(Queue)
    def initialize(@queue : Queue, @data : Marten::HTTP::Params::Data)
    end

    def run : ServiceResult(Queue)
      return failure(schema.errors) unless schema.valid?

      begin
        update_fields
        success(@queue)
      rescue ex : AASM::AASMException
        failure(:status, ex.message || "Invalid status transition")
      rescue ex : Marten::DB::Errors::InvalidRecord
        failure(ex.record.errors)
      end
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
