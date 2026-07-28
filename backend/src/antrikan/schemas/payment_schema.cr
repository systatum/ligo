module Antrikan
  class PaymentSchema < BaseSchema
    # Exact decimal string (BigFloat), same convention as Queue#total_price -
    # a float would risk precision loss on money.
    field :amount, :string, max_size: 255, required: true, strip: true
    field :method, :string, max_size: 50, required: false
    field :note, :string, max_size: 255, required: false
  end
end
