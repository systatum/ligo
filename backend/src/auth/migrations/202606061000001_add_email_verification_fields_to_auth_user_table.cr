class Migration::Auth::V202606061000001 < Marten::Migration
  depends_on :auth, "202605032047271_change_organization_id_on_auth_user_table"

  def plan
    add_column :auth_user, :is_email_address_verified, :bool, null: false, default: false
    add_column :auth_user, :email_verification_token, :string, max_size: 255, null: true
    add_column :auth_user, :email_verification_token_created_at, :date_time, null: true
    add_column :auth_user, :email_verification_token_expired_at, :date_time, null: true
  end
end
