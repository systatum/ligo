module Antrikan
  class QueuedItem::CreatorService < BaseService(QueuedItem)
    def initialize(@queue : Queue, @data : Marten::HTTP::Params::Data)
    end

    def run : ServiceResult(QueuedItem)
      return failure(schema.errors) unless schema.valid?
      return failure(:queue, "Cannot add items to a paid queue") unless unpaid?

      begin
        handler = schema.handler_id? ? Auth::User.get_by_hashed_id!(schema.handler_id!) : nil
        item = Item.get_by_slug!(slug: schema.item_slug!)

        qi = QueuedItem.new
        qi.id = UUID.random
        qi.queue = @queue
        qi.item = item
        qi.channel = item.channel!
        qi.unit_price = item.unit_price!
        qi.handler = handler
        qi.note = schema.note if schema.note?
        qi.quantity = schema.quantity if schema.quantity?

        if schema.status?
          if schema.status!.queued?
            qi.status = schema.status!.value
          else
            qi.change_status!(schema.status!.to_state)
          end
        end

        qi.save!
        publish_queued_item_created(qi)

        success(qi)
      rescue ex : AASM::AASMException
        failure(:status, ex.message || "Invalid status transition")
      rescue ex : Marten::DB::Errors::InvalidRecord
        failure(ex.record.errors)
      end
    end

    private def unpaid? : Bool
      @queue.payment_status! == PaymentStatus::UNPAID.value
    end

    private def schema
      @schema ||= QueuedItemSchema.new(@data)
    end

    private def publish_queued_item_created(qi : QueuedItem)
      ChannelEventPublisher.publish(qi.channel!,
        type: "queued_item_created",
        key: "queued_item",
        value: QueuedItemSerializer.soft_serialize(qi))
    end
  end
end
