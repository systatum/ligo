module Antrikan
  class QueuedItem < Marten::Model
    include SlugGenerator
    include ChangeTracker
    include SoftDeleter
    include QueuedTracker

    field :id, :uuid, primary_key: true
    field :slug, :string, max_size: 8, null: false, index: true, unique: true
    field :note, :string, max_size: 255, null: true, blank: true
    field :unit_price, :big_int, null: false, default: 0
    field :quantity, :int, null: false, default: 1
    # The logical ordering of the item in a queue.
    # To be used for front-end purposes
    field :rank, :int, null: true, blank: true
    # The timestamp of the last time the order was changed
    field :reranked_at, :date_time, null: true, blank: true
    field :updated_at, :date_time, null: false, auto_now: true

    field :queue, :many_to_one, to: Antrikan::Queue, related: :queued_items, null: false
    field :channel, :many_to_one, to: Antrikan::Channel, related: :queued_items, null: false
    field :item, :many_to_one, to: Antrikan::Item, related: :queued_items, null: false
    field :handler, :many_to_one, to: Auth::User, related: :handle_queued_items, null: true, blank: true

    # When batch-saving several queued items belonging to the same queue (see
    # QueuedItem::UpdaterService), set this to avoid re-syncing the parent queue
    # after every single save; the caller is then responsible for syncing once.
    property skip_parent_sync : Bool = false

    after_save :sync_parent_queue

    validate :validate_item

    private def sync_parent_queue
      return if skip_parent_sync

      queue!.sync_from_queued_items!
    end

    private def validate_item
      return if item!.channel_id == queue!.channel_id
      errors.add(:item_id, "Item must belong to the same queue channel")
    end
  end
end
