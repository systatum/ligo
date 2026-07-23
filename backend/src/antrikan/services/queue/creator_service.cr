module Antrikan
  class Queue::CreatorService < BaseService(Queue)
    def initialize(@channel : Channel, @data : Marten::HTTP::Params::Data)
    end

    def run : ServiceResult(Queue)
      return failure(schema.errors) unless schema.valid?

      queue = build_queue

      begin
        Queue.transaction do
          queue.save!
          attach_voucher!(queue)
          create_bulk_items!(queue)

          unless queue.payment_status! == PaymentStatus::UNPAID.value
            PayTimeDiscountApplierService.new(queue).run
          end
        end

        success(queue)
      rescue ex : TransactionError
        failure(ex.errors)
      rescue ex : AASM::AASMException
        failure(:status, ex.message || "Invalid status transition")
      rescue ex : Marten::DB::Errors::InvalidRecord
        failure(ex.record.errors)
      end
    end

    private def build_queue
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

      queue
    end

    private def attach_voucher!(queue : Queue)
      return unless schema.voucher_code?

      result = Voucher::RedeemerService.new(queue, schema.voucher_code!).run
      raise TransactionError.new(result.errors) unless result.success?
    end

    # `items` is a raw JSON array (same per-element shape `POST /queue/:slug/item/create`
    # accepts) - handled here directly rather than as a schema field, since
    # QueuedItemSchema is a Marten Schema and can't sit in an array field's
    # `serializable:` slot (that requires a JSON::Serializable type).
    private def create_bulk_items!(queue : Queue)
      json_items = @data["items"]?.as?(JSON::Any).try(&.as_a?)
      return if json_items.nil?

      json_items.each do |entry|
        entry_hash = entry.as_h?
        next if entry_hash.nil?

        item_result = QueuedItem::CreatorService.new(queue, entry_params(entry_hash)).run
        raise TransactionError.new(item_result.errors) unless item_result.success?
      end
    end

    private def entry_params(entry_hash : Hash(String, JSON::Any)) : Marten::HTTP::Params::Data
      raw_hash = Marten::HTTP::Params::Data::RawHash.new
      entry_hash.each { |k, v| raw_hash[k] = [v] of JSON::Any }
      Marten::HTTP::Params::Data.new(raw_hash)
    end

    private def schema
      @schema ||= QueueSchema.new(@data)
    end
  end
end
