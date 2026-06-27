module Antrikan
  struct QueuedItemUpdatePayload
    include JSON::Serializable

    property id : String
    property handler_id : String?
    property status : QueueStatus?
    property note : String?
  end
end
