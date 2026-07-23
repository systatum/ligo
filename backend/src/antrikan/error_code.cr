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
  end
end
