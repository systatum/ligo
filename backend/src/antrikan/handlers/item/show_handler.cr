module Antrikan
  class ItemShowHandler < RequestHandler
    include ItemHelper

    protect_from_forgery false
    http_method_names :get

    def get : Marten::HTTP::Response
      fetched_item = item
      ch = Channel.unscoped.filter(id: fetched_item.channel_id!).first
      raise Marten::HTTP::Errors::NotFound.new if ch.nil? || ch.deleted_at
      json ItemSerializer.serialize(fetched_item), status: 200
    end
  end
end
