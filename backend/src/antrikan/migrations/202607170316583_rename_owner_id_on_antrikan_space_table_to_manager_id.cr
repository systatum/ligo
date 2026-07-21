class Migration::Antrikan::V202607170316583 < Marten::Migration
  depends_on :antrikan, "202607170316582_add_business_id_to_antrikan_space_table"

  def plan
    rename_column :antrikan_space, :owner_id, :manager_id
  end
end
