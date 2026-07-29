class Migration::Antrikan::V202607211100001 < Marten::Migration
  depends_on :antrikan, "202607211000002_add_predeletable_state_and_cancel_note_columns"

  def plan
    add_column :antrikan_item, :carousel_image_ids, :json, null: true
  end
end
