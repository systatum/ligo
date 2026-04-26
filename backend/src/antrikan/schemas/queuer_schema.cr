module Antrikan
  class QueuerSchema < BaseSchema
    field :name, :string, max_size: 255, required: true, strip: true
    field :user_id, :string, required: false
  end
end
