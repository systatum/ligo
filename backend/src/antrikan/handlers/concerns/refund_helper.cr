module Antrikan
  module RefundHelper
    @refund : Refund?

    private def refund
      @refund ||= Refund.filter_by_slug(params["refund_slug"].to_s).get!
    end

    private def staff?
      refund.payment!.queue!.space!.staffed_by?(current_user!)
    end

    private def viewer_is_staff? : Bool
      user = current_user
      return false if user.nil?

      refund.payment!.queue!.space!.staffed_by?(user)
    end
  end
end
