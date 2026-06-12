require "./queuer_factory"

def create_queue(
  queuer : Antrikan::Queuer = create_queuer,
  channel : Antrikan::Channel = create_channel,
  handler : Auth::User? = nil,
  note : String? = nil,
  status : Antrikan::QueueStatus = Antrikan::QueueStatus::QUEUED,
  payment_status : Antrikan::PaymentStatus = Antrikan::PaymentStatus::UNPAID,
  total_price : Int64 = 0_i64,
  fully_paid_at : Time? = nil,
  attended_at : Time? = nil,
  packed_at : Time? = nil,
  ready_at : Time? = nil,
  dispatched_at : Time? = nil,
  delivered_at : Time? = nil,
) : Antrikan::Queue
  queue = Antrikan::Queue.new
  queue.queuer = queuer
  queue.channel = channel
  queue.handler = handler
  queue.note = note
  queue.status = status.value
  queue.payment_status = payment_status.value
  queue.total_price = total_price
  queue.fully_paid_at = fully_paid_at
  queue.attended_at = attended_at
  queue.packed_at = packed_at
  queue.ready_at = ready_at
  queue.dispatched_at = dispatched_at
  queue.delivered_at = delivered_at
  queue.save!

  queue
end
