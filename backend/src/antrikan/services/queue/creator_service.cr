module Antrikan
  class Queue::CreatorService < BaseService(Queue)
    def initialize(@channel : Channel, @data : Marten::HTTP::Params::Data)
    end

    def run : ServiceResult(Queue)
      return failure(schema.errors) unless schema.valid?

      begin
        queue = create_queue
        success(queue)
      rescue ex : AASM::AASMException
        failure(:status, ex.message || "Invalid status transition")
      rescue ex : Marten::DB::Errors::InvalidRecord
        failure(ex.record.errors)
      end
    end

    private def create_queue
      queuer = Queuer.get_by_hashed_id!(schema.queuer_id!)
      handler = schema.handler_id? ? Auth::User.get_by_hashed_id!(schema.handler_id!) : nil

      queue = Queue.new
      queue.channel = @channel
      queue.queuer = queuer
      queue.handler = handler
      queue.note = schema.note if schema.note?
      queue.payment_status = schema.payment_status!.value if schema.payment_status?
      queue.fully_paid_at = schema.fully_paid_at if schema.fully_paid_at?

      if schema.status?
        if schema.status!.queued?
          queue.status = schema.status!.value
        else
          queue.change_status!(schema.status!.to_state)
        end
      end

      queue.save!

      queue
    end

    private def schema
      @schema ||= QueueSchema.new(@data)
    end
  end
end
