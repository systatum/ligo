class Migration::Auth::V202606051559373 < Marten::Migration
  depends_on :auth, "202606051559372_create_auth_realm_table"

  def plan
    create_table :auth_realm_user do
      column :id, :big_int, primary_key: true, auto: true
      column :provider, :int, index: true
      column :provider_user_id, :string, max_size: 255, index: true
      column :acked_at, :date_time, null: true
      column :registration_webhook_content_id, :string, max_size: 255, null: true
      column :created_at, :date_time
      column :updated_at, :date_time
      column :user_id, :reference, to_table: :auth_user, to_column: :id
      column :realm_id, :reference, to_table: :auth_realm, to_column: :id

      unique_constraint :idx_provider_provider_user_id_unique, [:provider, :provider_user_id, :realm_id]
    end
  end
end
