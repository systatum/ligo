class Migration::Antrikan::V202607221200001 < Marten::Migration
  depends_on :antrikan, "202607211100001_add_carousel_image_ids_to_antrikan_item_table"

  def plan
    create_table :antrikan_voucher do
      column :id, :big_int, primary_key: true, auto: true
      column :code, :string, max_size: 255, unique: true, index: true
      column :name, :string, max_size: 255, null: true
      column :space_id, :reference, to_table: :antrikan_space, to_column: :id
      column :channel_id, :reference, to_table: :antrikan_channel, to_column: :id, null: true
      column :space_percentage_discount, :float, null: true
      column :space_fixed_discount, :big_int, null: true
      column :channel_percentage_discount, :float, null: true
      column :channel_fixed_discount, :big_int, null: true
      column :discountable_items, :json, null: true
      column :created_at, :date_time
      column :updated_at, :date_time
      column :deleted_at, :date_time, null: true, index: true
    end

    create_table :antrikan_applied_voucher do
      column :id, :big_int, primary_key: true, auto: true
      column :queue_id, :reference, to_table: :antrikan_queue, to_column: :id
      column :voucher_id, :reference, to_table: :antrikan_voucher, to_column: :id
      column :code, :string, max_size: 255
      column :name, :string, max_size: 255, null: true
      column :channel_id, :reference, to_table: :antrikan_channel, to_column: :id, null: true
      column :space_percentage_discount, :float, null: true
      column :space_fixed_discount, :big_int, null: true
      column :channel_percentage_discount, :float, null: true
      column :channel_fixed_discount, :big_int, null: true
      column :discountable_items, :json, null: true
      column :created_at, :date_time
    end
  end
end
