class Migration::Antrikan::V202607221200005 < Marten::Migration
  depends_on :antrikan, "202607221200004_add_active_window_to_antrikan_voucher_and_applied_voucher_tables"

  def plan
    add_column :antrikan_voucher, :anon_redeemable, :bool, null: false, default: true
    add_column :antrikan_applied_voucher, :anon_redeemable, :bool, null: false, default: true
  end
end
