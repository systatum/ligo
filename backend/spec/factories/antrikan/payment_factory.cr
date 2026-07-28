require "./queue_factory"
require "../user_factory"

def create_payment(
  queue : Antrikan::Queue = create_queue,
  recorded_by : Auth::User = create_user,
  amount : BigFloat = BigFloat.new(100),
  method : String? = nil,
  note : String? = nil,
) : Antrikan::Payment
  payment = Antrikan::Payment.new
  payment.queue = queue
  payment.recorded_by = recorded_by
  payment.amount = amount.to_s
  payment.method = method
  payment.note = note
  payment.save!

  payment
end
