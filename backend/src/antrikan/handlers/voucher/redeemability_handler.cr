module Antrikan
  class VoucherRedeemabilityHandler < RequestHandler
    protect_from_forgery false
    http_method_names :get

    def get : Marten::HTTP::Response
      queue_slug = request.query_params["queue_id"]?
      return render_error(422, ["queue_id query parameter is required"]) if queue_slug.nil?

      code = request.query_params["code"]?
      return render_error(422, ["code query parameter is required"]) if code.nil?

      queue = Queue.filter_by_slug(queue_slug).get!

      voucher = Voucher.find_by_code(code, queue.space_id!.as(Int32 | Int64))
      return json(redeemability(false, ErrorCode::VOUCHER_NOT_FOUND), status: 200) if voucher.nil?

      result = Voucher::RedemptionValidatorService.new(voucher, queue).run
      error_code = result.errors.try(&.first?).try(&.message)

      json(redeemability(result.success?, error_code), status: 200)
    end

    private def redeemability(redeemable : Bool, error_code : String?)
      {redeemable: redeemable, error_code: error_code}
    end
  end
end
