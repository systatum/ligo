class Migration::Antrikan::V202607221200007 < Marten::Migration
  depends_on :antrikan, "202607221200006_add_redeemer_id_to_antrikan_applied_voucher_table"

  def plan
    add_column :antrikan_voucher, :max_redeem_per_user, :int, null: false, default: -1
    add_column :antrikan_applied_voucher, :max_redeem_per_user, :int, null: false, default: -1
  end
end
