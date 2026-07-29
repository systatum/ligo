class Migration::Antrikan::V202607211000001 < Marten::Migration
  depends_on :antrikan, "202607210900001_add_unit_currency_to_antrikan_item_table"

  def plan
    execute(
      "UPDATE antrikan_queue SET status = status * 10",
      "UPDATE antrikan_queue SET status = status / 10"
    )
    execute(
      "UPDATE antrikan_queued_item SET status = status * 10",
      "UPDATE antrikan_queued_item SET status = status / 10"
    )
    change_column :antrikan_queue, :status, :int, default: 10
    change_column :antrikan_queued_item, :status, :int, default: 10
  end
end
