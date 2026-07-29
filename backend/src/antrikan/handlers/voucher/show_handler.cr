module Antrikan
  class VoucherShowHandler < RequestHandler
    include VoucherHelper

    protect_from_forgery false
    http_method_names :get

    def get : Marten::HTTP::Response
      raise Marten::HTTP::Errors::PermissionDenied.new unless authorized_for_voucher?

      json VoucherSerializer.serialize(voucher), status: 200
    end
  end
end
