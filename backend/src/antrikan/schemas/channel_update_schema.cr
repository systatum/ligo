module Antrikan
  class ChannelUpdateSchema < BaseSchema
    field :name, :string, max_size: 255, required: false, strip: true
    field :description, :string, required: false
    field :logo, :json, required: false, serializable: FilePayload
  end
end
