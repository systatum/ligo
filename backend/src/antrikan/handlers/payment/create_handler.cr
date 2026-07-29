module Antrikan
  class PaymentCreateHandler < RequestHandler
    include QueueHelper

    protect_from_forgery false
    http_method_names :post

    def post : Marten::HTTP::Response
      raise Marten::HTTP::Errors::PermissionDenied.new unless staff?

      result = Payment::CreatorService.new(queue, request.data, current_user!).run

      if result.success?
        json PaymentSerializer.serialize(result.data.not_nil!), status: 201
      else
        render_invalid_payload(result.errors)
      end
    end
  end
end
