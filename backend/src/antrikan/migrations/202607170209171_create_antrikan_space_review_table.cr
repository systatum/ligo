class Migration::Antrikan::V202607170209171 < Marten::Migration
  depends_on :antrikan, "202606200000001_add_rank_and_reranked_at_to_antrikan_queued_item_table"

  def plan
    create_table :antrikan_space_review do
      column :id, :big_int, primary_key: true, auto: true
      column :space_id, :reference, to_table: :antrikan_space, to_column: :id
      column :reviewer_id, :reference, to_table: :auth_user, to_column: :id

      column :rating, :float
      column :review, :text, null: true
      column :created_at, :date_time
      column :updated_at, :date_time
      column :deleted_at, :date_time, null: true, index: true

      unique_constraint :idx_space_review_space_reviewer_unique, [:space_id, :reviewer_id]
    end
  end
end
