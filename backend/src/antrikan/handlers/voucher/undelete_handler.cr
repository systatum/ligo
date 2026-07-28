module Antrikan
  class VoucherUndeleteHandler < RequestHandler
    include VoucherHelper

    protect_from_forgery false
    http_method_names :patch, :post

    def post : Marten::HTTP::Response
      patch
    end

    def patch : Marten::HTTP::Response
      unless authorized_for_voucher_including_deleted?
        raise Marten::HTTP::Errors::PermissionDenied.new
      end

      v = voucher_including_deleted
      v.deleted_at = nil
      v.save!
      json VoucherSerializer.serialize(v), status: 200
    end
  end
end
