class ProductVariant < Marten::Model
  include ChangeTracker

  field :id, :big_int, primary_key: true, auto: true
  field :product, :many_to_one, to: Product, related: :variants, on_delete: :cascade
  field :name, :string, max_size: 255, null: false, blank: true
  field :description, :text, null: true, blank: true
  field :created_at, :date_time, null: false, auto_now_add: true
  field :updated_at, :date_time, null: false, auto_now: true
end
