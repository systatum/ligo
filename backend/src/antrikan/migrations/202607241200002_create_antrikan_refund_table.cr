class Migration::Antrikan::V202607241200002 < Marten::Migration
  depends_on :antrikan, "202607241200001_create_antrikan_payment_table"

  def plan
    create_table :antrikan_refund do
      column :id, :uuid, primary_key: true
      column :slug, :string, max_size: 8, unique: true, index: true
      column :payment_id, :reference, to_table: :antrikan_payment, to_column: :id
      column :requested_by_id, :reference, to_table: :auth_user, to_column: :id, null: true
      column :reviewed_by_id, :reference, to_table: :auth_user, to_column: :id, null: true

      column :amount, :string, max_size: 255
      column :reason, :string, max_size: 255, null: true
      column :forceful, :bool, default: false
      column :status, :int, default: 0
      column :review_note, :string, max_size: 255, null: true
      column :image_ids, :json, null: true
      column :reviewed_at, :date_time, null: true
      column :created_at, :date_time
      column :deleted_at, :date_time, null: true, index: true
    end
  end
end
