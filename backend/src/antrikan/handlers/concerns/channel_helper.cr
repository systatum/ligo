module Antrikan
  module ChannelHelper
    @channel : Channel?
    @schema : ChannelSchema?

    def self.user_can_access?(user : Auth::User, channel : Channel) : Bool
      return false unless user.organization_id
      user.organization_id == channel.space!.owner!.organization_id
    end

    private def channel
      @channel ||= Channel
        .filter_by_hashed_id(params["channel_hashed_id"].to_s)
        .get!
    end

    private def channel_including_deleted
      @channel ||= Channel
        .filter_by_hashed_id(params["channel_hashed_id"].to_s, unscoped: true)
        .get!
    end

    private def schema
      @schema ||= ChannelSchema.new(request.data)
    end
  end
end
