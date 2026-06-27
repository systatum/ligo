module Antrikan
  struct QueuedItemRerankItem
    include JSON::Serializable

    property slug : String
    property rank : Int32
  end

  class QueuedItemRerankSchema < BaseSchema
    field :items, :json, required: true
    field :timestamp, :date_time, required: true
  end
end
