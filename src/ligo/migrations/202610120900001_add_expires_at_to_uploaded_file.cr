class Migration::Ligo::V202610120900001 < Marten::Migration
  depends_on :ligo, "202609132234251_create_realm_webhook"

  def plan
    add_column :ligo_uploaded_file, :expires_at, :date_time, null: true
  end
end
