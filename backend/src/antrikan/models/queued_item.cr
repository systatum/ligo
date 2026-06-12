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
    field :updated_at, :date_time, null: false, auto_now: true

    field :queue, :many_to_one, to: Antrikan::Queue, related: :queued_items, null: false
    field :channel, :many_to_one, to: Antrikan::Channel, related: :queued_items, null: false
    field :item, :many_to_one, to: Antrikan::Item, related: :queued_items, null: false
    field :handler, :many_to_one, to: Auth::User, related: :handle_queued_items, null: true, blank: true

    after_save :sync_parent_queue

    validate :validate_item

    private def sync_parent_queue
      queue!.sync_from_queued_items!
    end

    private def validate_item
      return if item!.channel_id == queue!.channel_id
      errors.add(:item_id, "Item must belong to the same queue channel")
    end
  end
end
