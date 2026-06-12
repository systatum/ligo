module Antrikan
  class QueuedItem::UpdaterService < BaseService(QueuedItem)
    def initialize(@queued_item : QueuedItem, @data : Marten::HTTP::Params::Data)
    end

    def run : ServiceResult(QueuedItem)
      return failure(schema.errors) unless schema.valid?

      begin
        update_fields
        success(@queued_item)
      rescue ex : AASM::AASMException
        failure(:status, ex.message || "Invalid status transition")
      rescue ex : Marten::DB::Errors::InvalidRecord
        failure(ex.record.errors)
      end
    end

    private def update_fields
      handler = schema.handler_id? ? Auth::User.get_by_hashed_id!(schema.handler_id!) : nil

      @queued_item.handler = handler if schema.handler_id?
      @queued_item.note = schema.note if schema.note?
      @queued_item.change_status!(schema.status!.to_state) if schema.status?

      @queued_item.save!
    end

    private def schema
      @schema ||= QueuedItemUpdateSchema.new(@data)
    end
  end
end
