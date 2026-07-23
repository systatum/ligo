module Antrikan
  # Persisted on `QueuedItem#applied_voucher_ids` - the ordered ids of every
  # `AppliedVoucher` discounting that item.
  class AppliedVoucherIds
    include JSON::Serializable

    property ids : Array(Int64)

    def initialize(@ids : Array(Int64) = [] of Int64)
    end
  end
end
