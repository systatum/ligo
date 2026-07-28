class Migration::Antrikan::V202607231200001 < Marten::Migration
  depends_on :antrikan, "202607221200007_add_max_redeem_per_user_to_antrikan_voucher_and_applied_voucher_tables"

  def plan
    change_column :antrikan_space, :address, :string, max_size: 255, null: true
    add_column :antrikan_space, :latitude, :float, null: true
    add_column :antrikan_space, :longitude, :float, null: true
    # References an entry id in data/countries/<country_code>_<ISO 3166-1 alpha-3>.json (e.g. data/countries/100_IDN.json).
    add_column :antrikan_space, :address_city_code, :int, null: true
    add_column :antrikan_space, :address_postal_code, :string, max_size: 20, null: true
  end
end
