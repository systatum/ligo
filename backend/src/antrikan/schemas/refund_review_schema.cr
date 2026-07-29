module Antrikan
  class RefundReviewSchema < BaseSchema
    field :review_note, :string, max_size: 255, required: false
  end
end
