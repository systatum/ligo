module Antrikan
  # Runs once, when a Queue's payment_status first leaves UNPAID: assigns every
  # eligible AppliedVoucher on the queue to its matching QueuedItems.
  class PayTimeDiscountApplierService < BaseService(Nil)
    def initialize(@queue : Queue)
    end

    def run : ServiceResult(Nil)
      applied_vouchers = @queue.applied_vouchers.to_a
      return success(nil) if applied_vouchers.empty?

      @queue.queued_items.each do |queued_item|
        already_applied = (queued_item.applied_voucher_ids.try(&.ids) || [] of Int64).to_set

        applied_vouchers.each do |applied_voucher|
          next if already_applied.includes?(applied_voucher.id!.to_i64)
          next unless eligible?(queued_item, applied_voucher)
          queued_item.add_applied_voucher!(applied_voucher)
        end
      end

      success(nil)
    end

    private def eligible?(queued_item : QueuedItem, applied_voucher : AppliedVoucher) : Bool
      return true unless applied_voucher.space_percentage_discount.nil? && applied_voucher.space_fixed_discount.nil?
      return true if channel_matches?(queued_item, applied_voucher)
      !item_rate(queued_item, applied_voucher).nil?
    end

    private def channel_matches?(queued_item : QueuedItem, applied_voucher : AppliedVoucher) : Bool
      return false if applied_voucher.channel_id.nil?
      return false if applied_voucher.channel_percentage_discount.nil? && applied_voucher.channel_fixed_discount.nil?
      applied_voucher.channel_id == queued_item.channel_id
    end

    private def item_rate(queued_item : QueuedItem, applied_voucher : AppliedVoucher)
      applied_voucher.discountable_item_entries.find { |e| e.item_id == queued_item.item!.slug! }
    end
  end
end
