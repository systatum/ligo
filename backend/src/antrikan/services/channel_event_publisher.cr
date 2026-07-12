module Antrikan
  module ChannelEventPublisher
    def self.publish(channel : Antrikan::Channel, type : String, key : String, value) : Nil
      payload = JSON.build do |json|
        json.object do
          json.field "type", type
          json.field "channel_id", channel.hashed_id
          json.field key, value
        end
      end
      Socky::Broadcaster.publish("antrikan:#{channel.hashed_id}", payload)
    end
  end
end
