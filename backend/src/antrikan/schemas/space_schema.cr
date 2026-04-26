module Antrikan
  class SpaceSchema < BaseSchema
    field :name, :string, max_size: 255, required: true, strip: true
    field :need_manual_approval, :bool, required: false
    field :has_operating_hours, :bool, required: false
    field :require_registered_queuer, :bool, required: false
    field :logo, :json, required: false, serializable: FilePayload
  end
end
