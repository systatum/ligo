class Migration::Auth::V202606051559374 < Marten::Migration
  depends_on :auth, "202606051559373_create_auth_realm_user_table"

  def plan
    delete_table :auth_provider
  end
end
