class Migration::Antrikan::V202607241200001 < Marten::Migration
  depends_on :antrikan, "202607231200005_add_max_item_piece_to_antrikan_channel_table"

  def plan
    create_table :antrikan_payment do
      column :id, :big_int, primary_key: true, auto: true
      column :queue_id, :reference, to_table: :antrikan_queue, to_column: :id
      column :recorded_by_id, :reference, to_table: :auth_user, to_column: :id

      column :amount, :string, max_size: 255
      column :method, :string, max_size: 50, null: true
      column :note, :string, max_size: 255, null: true
      column :created_at, :date_time
      column :deleted_at, :date_time, null: true, index: true
    end
  end
end
