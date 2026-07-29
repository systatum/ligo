module Antrikan
  module PaymentHelper
    @payment : Payment?

    private def payment
      @payment ||= Payment
        .filter_by_hashed_id(params["payment_hashed_id"].to_s)
        .get!
    end

    private def staff?
      payment.queue!.space!.staffed_by?(current_user!)
    end
  end
end
