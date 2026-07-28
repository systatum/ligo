class Migration::Antrikan::V202607231200005 < Marten::Migration
  depends_on :antrikan, "202607231200004_add_enforce_operating_hours_to_antrikan_channel_table"

  def plan
    add_column :antrikan_channel, :max_item_piece, :int, null: false, default: -1
  end
end
