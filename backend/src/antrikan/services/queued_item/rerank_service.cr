module Antrikan
  class QueuedItem::RerankService < BaseService(Array(QueuedItem))
    def initialize(@queue : Queue, @data : Marten::HTTP::Params::Data)
    end

    def run : ServiceResult(Array(QueuedItem))
      return failure(schema.errors) unless schema.valid?

      items = Array(QueuedItemRerankItem).from_json(schema.items!.to_json)
      return failure(:items, "must be a non-empty array") if items.empty?

      slugs = items.map(&.slug)
      queue_items = @queue.queued_items.filter(slug__in: slugs).to_a
      return failure(:items, "Some items not found in this queue") unless queue_items.size == slugs.size

      timestamp = schema.timestamp!
      queue_items.each do |qi|
        if qi.reranked_at && qi.reranked_at.not_nil! >= timestamp
          return failure(:timestamp, "OLDORDER")
        end
      end

      slug_to_item = queue_items.index_by(&.slug!)

      items.each do |item|
        qi = slug_to_item[item.slug]
        qi.rank = item.rank
        qi.reranked_at = Time.utc
      end

      queue_items.each(&.save!)

      success(queue_items)
    rescue ex : Marten::DB::Errors::InvalidRecord
      failure(ex.record.errors)
    rescue ex : JSON::SerializableError
      failure(:items, ex.message || "Invalid items format")
    end

    private def schema
      @schema ||= QueuedItemRerankSchema.new(@data)
    end
  end
end
