class Migration::Antrikan::V202607170435521 < Marten::Migration
  depends_on :antrikan, "202607170316584_add_address_phone_email_to_antrikan_space_table"

  def plan
    rename_column :antrikan_space, :business_id, :owner_id
  end
end
