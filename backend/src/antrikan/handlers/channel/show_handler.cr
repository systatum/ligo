module Antrikan
  class ChannelShowHandler < RequestHandler
    include ChannelHelper

    protect_from_forgery false
    http_method_names :get

    def get : Marten::HTTP::Response
      json ChannelSerializer.serialize(channel), status: 200
    end
  end
end
