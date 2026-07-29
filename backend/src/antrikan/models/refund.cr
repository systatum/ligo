module Antrikan
  # A reviewed request to give back some or all of a specific Payment's amount.
  # Always drawn down against one Payment (not a vague queue-wide pool) - see
  # Payment#remaining_refundable_amount.
  class Refund < Marten::Model
    include SlugGenerator
    include ChangeTracker
    include SoftDeleter

    field :id, :uuid, primary_key: true
    field :slug, :string, max_size: 8, null: false, index: true, unique: true
    field :amount, :string, max_size: 255, null: false
    field :reason, :string, max_size: 255, null: true, blank: true
    field :forceful, :bool, null: false, default: false
    field :status, :int, null: false, default: RefundStatus::PENDING.value
    field :review_note, :string, max_size: 255, null: true, blank: true
    field :image_ids, :json, null: true, blank: true, serializable: UploadedFileIds
    field :reviewed_at, :date_time, null: true, blank: true
    field :created_at, :date_time, null: false, auto_now_add: true

    field :payment, :many_to_one, to: Antrikan::Payment, related: :refunds
    field :requested_by, :many_to_one, to: Auth::User, related: :requested_refunds, null: true, blank: true
    field :reviewed_by, :many_to_one, to: Auth::User, related: :reviewed_refunds, null: true, blank: true

    scope :accepted { filter(status: RefundStatus::ACCEPTED.value, deleted_at: nil) }

    validate :validate_amount_positive
    validate :validate_reviewed_by_present_when_reviewed

    private def validate_amount_positive
      return unless amount?

      unless BigFloat.new(amount!) > BigFloat.new(0)
        errors.add(:amount, "must be greater than 0")
      end
    end

    private def validate_reviewed_by_present_when_reviewed
      return if status! == RefundStatus::PENDING.value
      return if reviewed_by_id?

      errors.add(:reviewed_by, "must be set once a refund is accepted or rejected")
    end
  end
end
