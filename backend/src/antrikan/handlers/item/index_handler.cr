module Antrikan
  class ItemIndexHandler < RequestHandler
    include ChannelHelper

    protect_from_forgery false
    http_method_names :get

    def get : Marten::HTTP::Response
      with_deleted = request.query_params["with_deleted"]? == "true"

      items = with_deleted ? Item.unscoped : Item.all
      items = items.filter(channel_id: channel.id).order(:order)

      result = items.map { |item| ItemSerializer.soft_serialize(item) }
      json(result, status: 200)
    end
  end
end
