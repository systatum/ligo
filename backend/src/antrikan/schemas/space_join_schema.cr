module Antrikan
  class SpaceJoinSchema < BaseSchema
    field :users, :array, required: false, of: :json, serializable: SpaceJoinUserPayload
  end
end
