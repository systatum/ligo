module Antrikan
  class ChannelUpdateHandler < RequestHandler
    include ChannelHelper

    protect_from_forgery false
    http_method_names :patch, :post

    def post : Marten::HTTP::Response
      patch
    end

    def patch : Marten::HTTP::Response
      raise Marten::HTTP::Errors::PermissionDenied.new unless current_user!.admin?

      result = Channel::UpdaterService.new(channel, request.data).run

      if result.success?
        json ChannelSerializer.serialize(result.data.not_nil!), status: 200
      else
        render_invalid_payload result.errors
      end
    end
  end
end
