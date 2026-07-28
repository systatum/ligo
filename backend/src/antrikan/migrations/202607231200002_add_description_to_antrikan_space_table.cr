class Migration::Antrikan::V202607231200002 < Marten::Migration
  depends_on :antrikan, "202607231200001_add_geo_and_postal_fields_to_antrikan_space_table"

  def plan
    add_column :antrikan_space, :description, :text, null: true
  end
end
