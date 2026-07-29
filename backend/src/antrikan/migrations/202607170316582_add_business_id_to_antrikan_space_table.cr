class Migration::Antrikan::V202607170316582 < Marten::Migration
  depends_on :antrikan, "202607170316581_create_antrikan_business_table"

  def plan
    add_column :antrikan_space, :business_id, :reference, to_table: :antrikan_business, to_column: :id
  end
end
