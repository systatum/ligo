require "../user_factory"
require "./space_factory"

def create_channel(
  space : Antrikan::Space = create_space,
  name : String = "Beverages",
  description : String? = nil,
  logo_file_id : UUID? = nil,
) : Antrikan::Channel
  channel = Antrikan::Channel.new
  channel.space = space
  channel.name = name
  channel.description = description
  channel.logo_file_id = logo_file_id
  channel.save!

  channel
end
