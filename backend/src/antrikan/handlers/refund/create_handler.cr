module Antrikan
  class RefundCreateHandler < RequestHandler
    include PaymentHelper

    protect_from_forgery false
    http_method_names :post

    def post : Marten::HTTP::Response
      result = Refund::RequestService.new(payment, request.data, current_user).run

      if result.success?
        json RefundSerializer.serialize(result.data.not_nil!), status: 201
      else
        render_invalid_payload(result.errors)
      end
    end
  end
end
