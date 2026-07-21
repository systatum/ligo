class Migration::Auth::V202607140731561 < Marten::Migration
  depends_on :auth, "202606051559374_delete_auth_provider_table"

  def plan
    # 9000 is Auth::Role::OWNER
    add_column :auth_realm, :default_role, :int, null: false, default: 9000
  end
end
