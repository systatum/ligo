class Migration::Antrikan::V202607301200003 < Marten::Migration
  depends_on :antrikan, "202607301200002_add_allow_anonymous_reviewer_and_nullable_reviewer"

  def plan
    add_column :antrikan_space_review, :channel_id, :reference, to_table: :antrikan_channel, to_column: :id, null: true
    add_column :antrikan_space_review, :item_id, :reference, to_table: :antrikan_item, to_column: :id, null: true
  end
end
