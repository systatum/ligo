module Antrikan
  class ChannelDeleteHandler < RequestHandler
    include ChannelHelper

    protect_from_forgery false
    http_method_names :delete

    def delete : Marten::HTTP::Response
      raise Marten::HTTP::Errors::PermissionDenied.new unless current_user!.admin?

      channel.soft_delete!
      json ChannelSerializer.serialize(channel), status: 200
    end
  end
end
