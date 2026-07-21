class Migration::Antrikan::V202607170532591 < Marten::Migration
  depends_on :antrikan, "202607170435521_rename_business_id_on_antrikan_space_table_to_owner_id"

  def plan
    add_column :antrikan_space, :carousel_image_ids, :json, null: true
  end
end
