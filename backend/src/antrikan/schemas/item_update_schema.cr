module Antrikan
  class ItemUpdateSchema < BaseSchema
    field :name, :string, max_size: 255, required: false, strip: true
    field :order, :int, required: false
    field :daily_cap, :int, required: false
    field :is_monitored, :bool, required: false
    field :description, :string, required: false
    field :main_image, :json, required: false, serializable: FilePayload
  end
end
