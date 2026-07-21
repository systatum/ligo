require "./enums/**"
require "./errors.cr"
require "./handlers/concerns/**"
require "./handlers/**"
require "./models/concerns/**"
require "./models/**"
require "./routes"
require "./schemas/**"
require "./serializers/**"
require "./services/**"
require "./structs/**"

Socky::ChannelAuthorizer.register_resolver("antrikan") do |user, local_key|
  channel = Antrikan::Channel.get_by_hashed_id(local_key)
  !!channel && Antrikan::ChannelHelper.user_can_access?(user, channel)
end

Socky::Broadcaster.start_subscriber

module Antrikan
  class App < Marten::App
    label "antrikan"
  end
end
