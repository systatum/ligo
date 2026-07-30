class Migration::Antrikan::V202607301200004 < Marten::Migration
  depends_on :antrikan, "202607301200003_add_channel_and_item_to_space_review_table"

  def plan
    add_column :antrikan_space_review, :image_ids, :json, null: true
  end
end
