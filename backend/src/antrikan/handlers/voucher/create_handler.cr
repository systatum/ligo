module Antrikan
  class VoucherCreateHandler < RequestHandler
    include SpaceHelper

    protect_from_forgery false
    http_method_names :post

    def post : Marten::HTTP::Response
      raise Marten::HTTP::Errors::PermissionDenied.new unless owner_of_space?

      voucher = Voucher.new
      voucher.space = space
      result = Voucher::UpserterService.new(voucher, request.data).run

      if result.success?
        json VoucherSerializer.serialize(result.data.not_nil!), status: 201
      else
        render_invalid_payload(result.errors)
      end
    end
  end
end
