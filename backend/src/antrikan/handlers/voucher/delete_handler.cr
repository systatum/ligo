module Antrikan
  class VoucherDeleteHandler < RequestHandler
    include VoucherHelper

    protect_from_forgery false
    http_method_names :delete

    def delete : Marten::HTTP::Response
      raise Marten::HTTP::Errors::PermissionDenied.new unless authorized_for_voucher?

      voucher.soft_delete!
      json VoucherSerializer.serialize(voucher), status: 200
    end
  end
end
