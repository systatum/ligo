module Antrikan
  class Payment < Marten::Model
    include ChangeTracker
    include SoftDeleter
    include IdConcealer

    field :id, :big_int, primary_key: true, auto: true
    field :amount, :string, max_size: 255, null: false
    field :method, :string, max_size: 50, null: true, blank: true
    field :note, :string, max_size: 255, null: true, blank: true
    field :created_at, :date_time, null: false, auto_now_add: true

    field :queue, :many_to_one, to: Antrikan::Queue, related: :payments
    field :recorded_by, :many_to_one, to: Auth::User, related: :recorded_payments

    validate :validate_amount_positive

    def amount_refunded : BigFloat
      refunds.accepted.sum(BigFloat.new(0)) { |r| BigFloat.new(r.amount!) }
    end

    def remaining_refundable_amount : BigFloat
      BigFloat.new(amount!) - amount_refunded
    end

    private def validate_amount_positive
      return unless amount?

      unless BigFloat.new(amount!) > BigFloat.new(0)
        errors.add(:amount, "must be greater than 0")
      end
    end
  end
end
