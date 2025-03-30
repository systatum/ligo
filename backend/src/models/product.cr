# A product represent purchasable item. A product can have many variants,
# ie for "Self-ligating Brace" we may have color green, red, blue, etc,
# those can be categorized as variants, complete with their own pricing rules
class Product < Marten::Model
  include IdConcealer
  include ChangeTracker
  include SoftDeleter

  field :id, :big_int, primary_key: true, auto: true
  field :name, :string, max_size: 255, null: false, blank: false
  field :short_description, :text, null: true, blank: true
  field :note, :text, null: true, blank: true
  field :created_at, :date_time, null: false, auto_now_add: true
  field :updated_at, :date_time, null: false, auto_now: true

  field :organization, :many_to_one, to: Auth::Organization, related: :products
end
