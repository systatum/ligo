module Antrikan
  class RefundAcceptHandler < RequestHandler
    include RefundHelper

    protect_from_forgery false
    http_method_names :post

    def post : Marten::HTTP::Response
      raise Marten::HTTP::Errors::PermissionDenied.new unless staff?

      result = Refund::ReviewService.new(refund, true, current_user!, request.data).run

      if result.success?
        json RefundSerializer.serialize(result.data.not_nil!, viewer_is_staff: true), status: 200
      else
        render_invalid_payload(result.errors)
      end
    end
  end
end
