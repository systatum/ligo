class Migration::Antrikan::V202607301200001 < Marten::Migration
  depends_on :antrikan, "202607281200001_change_antrikan_queue_channel_to_space"

  def plan
    add_column :antrikan_channel, :parent_channel_id, :reference, to_table: :antrikan_channel, to_column: :id, null: true
  end
end
