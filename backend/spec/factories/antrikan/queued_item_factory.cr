require "./queue_factory"
require "./item_factory"

def create_queued_item(
  queue : Antrikan::Queue = create_queue,
  channel : Antrikan::Channel? = nil,
  item : Antrikan::Item? = nil,
  handler : Auth::User? = nil,
  id : UUID = UUID.random,
  status : Antrikan::QueueStatus = Antrikan::QueueStatus::QUEUED,
  note : String? = nil,
  unit_price : Int64 = 0_i64,
  quantity : Int32 = 1,
  rank : Int32? = nil,
  attended_at : Time? = nil,
  packed_at : Time? = nil,
  ready_at : Time? = nil,
  dispatched_at : Time? = nil,
  delivered_at : Time? = nil,
) : Antrikan::QueuedItem
  item_channel = channel || queue.channel!
  queue_item = item || create_item(channel: item_channel)

  queued_item = Antrikan::QueuedItem.new
  queued_item.id = id
  queued_item.queue = queue
  queued_item.channel = item_channel
  queued_item.item = queue_item
  queued_item.handler = handler
  queued_item.status = status.value
  queued_item.note = note
  queued_item.unit_price = unit_price
  queued_item.quantity = quantity
  queued_item.rank = rank if rank
  queued_item.attended_at = attended_at
  queued_item.packed_at = packed_at
  queued_item.ready_at = ready_at
  queued_item.dispatched_at = dispatched_at
  queued_item.delivered_at = delivered_at
  queued_item.save!

  queued_item
end
