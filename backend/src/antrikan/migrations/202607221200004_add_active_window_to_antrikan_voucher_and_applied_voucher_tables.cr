class Migration::Antrikan::V202607221200004 < Marten::Migration
  depends_on :antrikan, "202607221200003_change_antrikan_queue_total_price_to_string"

  def plan
    add_column :antrikan_voucher, :indeterminate, :bool, null: false, default: true
    add_column :antrikan_voucher, :starts_at, :date_time, null: true
    add_column :antrikan_voucher, :expires_at, :date_time, null: true

    add_column :antrikan_applied_voucher, :indeterminate, :bool, null: false, default: true
    add_column :antrikan_applied_voucher, :starts_at, :date_time, null: true
    add_column :antrikan_applied_voucher, :expires_at, :date_time, null: true
  end
end
