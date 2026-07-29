require "./payment_factory"
require "../user_factory"

def create_refund(
  payment : Antrikan::Payment = create_payment,
  requested_by : Auth::User? = nil,
  reviewed_by : Auth::User? = nil,
  amount : BigFloat = BigFloat.new(10),
  reason : String? = nil,
  forceful : Bool = false,
  status : Antrikan::RefundStatus = Antrikan::RefundStatus::PENDING,
  review_note : String? = nil,
  image_ids : UploadedFileIds? = nil,
  reviewed_at : Time? = nil,
) : Antrikan::Refund
  reviewed_by = create_user if reviewed_by.nil? && status != Antrikan::RefundStatus::PENDING

  refund = Antrikan::Refund.new
  refund.id = UUID.random
  refund.payment = payment
  refund.requested_by = requested_by
  refund.reviewed_by = reviewed_by
  refund.amount = amount.to_s
  refund.reason = reason
  refund.forceful = forceful
  refund.status = status.value
  refund.review_note = review_note
  refund.image_ids = image_ids
  refund.reviewed_at = reviewed_at
  refund.save!

  refund
end
