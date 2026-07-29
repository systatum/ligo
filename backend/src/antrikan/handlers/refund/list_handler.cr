module Antrikan
  class RefundListHandler < RequestHandler
    include PaymentHelper

    protect_from_forgery false
    http_method_names :get

    def get : Marten::HTTP::Response
      raise Marten::HTTP::Errors::PermissionDenied.new unless staff?

      refunds = payment.refunds.filter(deleted_at: nil)
      result = refunds.map { |refund| RefundSerializer.soft_serialize(refund, viewer_is_staff: true) }

      json({refunds: result}, status: 200)
    end
  end
end
