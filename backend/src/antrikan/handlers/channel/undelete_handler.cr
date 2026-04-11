module Antrikan
  class ChannelUndeleteHandler < RequestHandler
    include ChannelHelper

    protect_from_forgery false
    http_method_names :patch, :post

    def post : Marten::HTTP::Response
      patch
    end

    def patch : Marten::HTTP::Response
      raise Marten::HTTP::Errors::PermissionDenied.new unless current_user!.admin?

      ch = channel_including_deleted
      ch.deleted_at = nil
      ch.save!
      json ChannelSerializer.serialize(ch), status: 200
    end
  end
end
