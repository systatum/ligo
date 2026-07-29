class Migration::Main::V202607171200001 < Marten::Migration
  depends_on :main, "202606051559371_create_main_webhook_delivery_table"
  depends_on :auth, "202607140731561_add_default_role_to_auth_realm_table"

  def plan
    add_column :main_uploaded_file, :uploaded_by_id, :reference, to_table: :auth_user, to_column: :id, null: true
  end
end
