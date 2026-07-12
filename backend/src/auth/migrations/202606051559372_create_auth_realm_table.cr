class Migration::Auth::V202606051559372 < Marten::Migration
  depends_on :auth, "202605032047271_change_organization_id_on_auth_user_table"

  def plan
    create_table :auth_realm do
      column :id, :string, max_size: 12, primary_key: true
      column :app_name, :string, max_size: 255
      column :hashed_api_secret_key, :string, max_size: 65
      column :hashed_api_client_key, :string, max_size: 65
      column :webhook_secret, :string, max_size: 15
      column :ack_semantic, :enum, values: ["NONE", "OPTIONAL", "MUTUAL"]
      column :max_ack_retry_attempts, :int, null: true, default: 50
      column :registration_redirection_uri, :string, max_size: 200, null: true
      column :registration_ack_uri, :string, max_size: 200, null: true
      column :app_id, :string, max_size: 255
      column :app_secret, :string, max_size: 255
      column :deleted_at, :date_time, null: true, index: true
      column :created_at, :date_time
      column :updated_at, :date_time
    end
  end
end
