class Migration::Antrikan::V202607210900001 < Marten::Migration
  depends_on :antrikan, "202607170532591_add_carousel_image_ids_to_antrikan_space_table"

  def plan
    # 100 = Antrikan::Currency::IDR
    add_column :antrikan_item, :unit_currency, :int, null: false, default: 100
  end
end
