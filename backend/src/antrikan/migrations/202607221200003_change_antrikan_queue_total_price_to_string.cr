class Migration::Antrikan::V202607221200003 < Marten::Migration
  depends_on :antrikan, "202607221200002_add_applied_voucher_ids_to_antrikan_queued_item_table"

  def plan
    # total_price now holds an exact BigFloat decimal string - discounts can
    # produce fractional amounts, and rounding to an int would misbill the customer.
    change_column :antrikan_queue, :total_price, :string, max_size: 255, default: "0.0"
  end
end
