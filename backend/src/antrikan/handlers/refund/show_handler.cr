module Antrikan
  class RefundShowHandler < RequestHandler
    include RefundHelper

    protect_from_forgery false
    http_method_names :get

    def get : Marten::HTTP::Response
      json RefundSerializer.serialize(refund, viewer_is_staff: viewer_is_staff?), status: 200
    end
  end
end
