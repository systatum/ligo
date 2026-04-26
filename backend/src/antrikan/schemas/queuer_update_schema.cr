module Antrikan
  class QueuerUpdateSchema < BaseSchema
    field :queuer_id, :string, required: true
    field :password, :string, required: true
    field :name, :string, max_size: 255, required: false, strip: true
    field :user_id, :string, required: false
  end
end
