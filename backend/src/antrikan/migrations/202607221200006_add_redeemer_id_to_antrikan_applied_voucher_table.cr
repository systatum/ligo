class Migration::Antrikan::V202607221200006 < Marten::Migration
  depends_on :antrikan, "202607221200005_add_anon_redeemable_to_antrikan_voucher_and_applied_voucher_tables"

  def plan
    add_column :antrikan_applied_voucher, :redeemer_id, :reference, to_table: :auth_user, to_column: :id, null: true
  end
end
