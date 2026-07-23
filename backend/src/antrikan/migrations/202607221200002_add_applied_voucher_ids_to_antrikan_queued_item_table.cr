class Migration::Antrikan::V202607221200002 < Marten::Migration
  depends_on :antrikan, "202607221200001_create_antrikan_voucher_and_applied_voucher_tables"

  def plan
    add_column :antrikan_queued_item, :applied_voucher_ids, :json, null: true
  end
end
