class Migration::Antrikan::V202607231200003 < Marten::Migration
  depends_on :antrikan, "202607231200002_add_description_to_antrikan_space_table"

  def plan
    change_column :antrikan_operating_hour, :space_id, :reference, to_table: :antrikan_space, to_column: :id, null: true
    add_column :antrikan_operating_hour, :channel_id, :reference, to_table: :antrikan_channel, to_column: :id, null: true
    add_column :antrikan_operating_hour, :item_id, :reference, to_table: :antrikan_item, to_column: :id, null: true
  end
end
