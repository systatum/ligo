module Antrikan
  class PaymentListHandler < RequestHandler
    include QueueHelper

    protect_from_forgery false
    http_method_names :get

    def get : Marten::HTTP::Response
      raise Marten::HTTP::Errors::PermissionDenied.new unless staff?

      payments = queue.payments.filter(deleted_at: nil)
      result = payments.map { |payment| PaymentSerializer.soft_serialize(payment) }

      json(result, status: 200)
    end
  end
end
