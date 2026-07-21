class Migration::Antrikan::V202607170316584 < Marten::Migration
  depends_on :antrikan, "202607170316583_rename_owner_id_on_antrikan_space_table_to_manager_id"

  def plan
    add_column :antrikan_space, :address, :text, null: true
    add_column :antrikan_space, :phone, :string, max_size: 20, null: true
    add_column :antrikan_space, :email, :string, max_size: 255, null: true
  end
end
