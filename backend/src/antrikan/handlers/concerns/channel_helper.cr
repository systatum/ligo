module Antrikan
  module ChannelHelper
    @channel : Channel?
    @schema : ChannelSchema?

    def self.user_can_access?(user : Auth::User, channel : Channel) : Bool
      return false unless user.organization_id
      user.organization_id == channel.space!.manager!.organization_id
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

    private def authorized_for_channel?
      channel.space!.owned_by?(current_user!)
    end

    private def authorized_for_channel_including_deleted?
      channel_including_deleted.space!.owned_by?(current_user!)
    end

    private def schema
      @schema ||= ChannelSchema.new(request.data)
    end
  end
end
