module Antrikan
  class VoucherIndexHandler < RequestHandler
    include SpaceHelper

    protect_from_forgery false
    http_method_names :get

    def get : Marten::HTTP::Response
      raise Marten::HTTP::Errors::PermissionDenied.new unless owner_of_space?

      with_deleted = request.query_params["with_deleted"]? == "true"

      vouchers = with_deleted ? Voucher.unscoped : Voucher.all
      vouchers = vouchers.filter(space_id: space.id)

      result = vouchers.map { |v| VoucherSerializer.soft_serialize(v) }
      json(result, status: 200)
    end
  end
end
