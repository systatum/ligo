class Migration::Antrikan::V202607281200001 < Marten::Migration
  depends_on :antrikan, "202607241200002_create_antrikan_refund_table"

  def plan
    add_column :antrikan_queue, :space_id, :reference, to_table: :antrikan_space, to_column: :id, null: false
    remove_column :antrikan_queue, :channel_id
  end
end
