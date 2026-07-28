module Antrikan
  # Centralized machine-readable error codes returned to clients
  module ErrorCode
    # -- Voucher --

    # No voucher exists with this code, scoped to the queue's space.
    VOUCHER_NOT_FOUND = "ERR_VOUCH_NOT_FOUND"

    # The voucher is outside its active window
    VOUCHER_INACTIVE = "ERR_VOUCH_INACTIVE"

    # The voucher requires a registered user to redeem,
    # but the queue's queuer has no linked registered user.
    VOUCHER_NOT_ANON_REDEEMABLE = "ERR_VOUCH_NOANON"

    # The redeemer already redeemed this voucher max_redeem_per_user times.
    VOUCHER_REDEEMER_MAXED_QUOTA = "ERR_VOUCH_REDEEMER_MAXED_QUOTA"

    # -- Payment / Refund --

    # A refund was requested against a payment whose queue is still UNPAID -
    # there is no collected money to refund yet.
    PAYMENT_UNPAID = "ERR_PAYMENT_UNPAID"

    # Accepting this refund (or the request itself, without forceful: true)
    # would leave the payment's refundable balance negative.
    REFUND_NEGATIVE_BALANCE = "ERR_REFUND_NEGATIVE_BALANCE"

    # This refund has already been accepted or rejected and cannot be reviewed again.
    REFUND_ALREADY_REVIEWED = "ERR_REFUND_ALREADY_REVIEWED"

    # A queue cannot be reopened to UNPAID while it has a pending or accepted refund.
    REFUND_BLOCKS_REOPEN = "ERR_REFUND_BLOCKS_REOPEN"
  end
end
