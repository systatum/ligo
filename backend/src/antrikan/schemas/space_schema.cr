module Antrikan
  class SpaceSchema < BaseSchema
    field :name, :string, max_size: 255, required: true, strip: true
    field :need_manual_approval, :bool, required: false
    field :has_operating_hours, :bool, required: false
  end
end
