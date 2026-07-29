module Antrikan
  struct QueuedItemUpdatePayload
    include JSON::Serializable

    property id : String
    property handler_id : String? # the user's hashed ID
    property status : QueueStatus?
    property note : String?
    property cancel_note : String?
  end
end
