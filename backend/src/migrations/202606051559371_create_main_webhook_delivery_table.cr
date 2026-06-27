class Migration::Main::V202606051559371 < Marten::Migration
  depends_on :main, "202604042028121_auto"

  def plan
    create_table :main_webhook_delivery do
      column :id, :big_int, primary_key: true, auto: true
      column :content_id, :string, max_size: 200
      column :succeeded, :bool
      column :deleted_at, :date_time, null: true, index: true
      column :created_at, :date_time
      column :updated_at, :date_time
    end
  end
end
