require "../user_factory"
require "./space_factory"

def create_channel(
  space : Antrikan::Space = create_space,
  name : String = "Beverages",
  description : String? = nil,
  logo_file_id : UUID? = nil,
  predeletable_state : Antrikan::QueueStatus? = nil,
  enforce_operating_hours : Bool = false,
  max_item_piece : Int32 = -1,
  parent_channel : Antrikan::Channel? = nil,
) : Antrikan::Channel
  channel = Antrikan::Channel.new
  channel.space = space
  channel.name = name
  channel.description = description
  channel.logo_file_id = logo_file_id
  channel.predeletable_state = predeletable_state.value if predeletable_state
  channel.enforce_operating_hours = enforce_operating_hours
  channel.max_item_piece = max_item_piece
  channel.parent_channel = parent_channel
  channel.save!

  channel
end
