class Migration::Antrikan::V202607170316581 < Marten::Migration
  depends_on :antrikan, "202607170209171_create_antrikan_space_review_table"

  def plan
    create_table :antrikan_business do
      column :id, :big_int, primary_key: true, auto: true
      column :name, :string, max_size: 255
      column :created_at, :date_time
      column :updated_at, :date_time
      column :deleted_at, :date_time, null: true, index: true
      column :owner_id, :reference, to_table: :auth_user, to_column: :id
    end
  end
end
