module Antrikan
  class ChannelIndexHandler < RequestHandler
    include SpaceHelper

    protect_from_forgery false
    http_method_names :get

    def get : Marten::HTTP::Response
      with_deleted = request.query_params["with_deleted"]? == "true"

      channels = with_deleted ? Channel.unscoped : Channel.all
      channels = channels.filter(space_id: space.id)

      result = channels.map { |ch| ChannelSerializer.soft_serialize(ch) }
      json(result, status: 200)
    end
  end
end
