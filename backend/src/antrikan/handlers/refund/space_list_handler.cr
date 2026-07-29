module Antrikan
  class RefundSpaceListHandler < RequestHandler
    include SpaceHelper

    protect_from_forgery false
    http_method_names :get

    def get : Marten::HTTP::Response
      raise Marten::HTTP::Errors::PermissionDenied.new unless space.staffed_by?(current_user!)

      refunds = Refund.filter(payment__queue__space_id: space.id!, deleted_at: nil)
      result = refunds.map { |refund| RefundSerializer.soft_serialize(refund, viewer_is_staff: true) }

      json(result, status: 200)
    end
  end
end
