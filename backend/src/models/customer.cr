class Customer < Marten::Model
  include SlugGenerator
  include ChangeTracker

  field :id, :big_int, primary_key: true, auto: true
  field :slug, :string, max_size: 6, null: false, index: true, unique: true
  field :first_name, :string, max_size: 128, null: false, blank: false
  field :middle_name, :string, max_size: 128, null: true, blank: true
  field :last_name, :string, max_size: 128, null: true, blank: true
  field :gender, :int, null: true, blank: true
  field :birthday, :date, null: true, blank: true
  field :note, :text, null: true, blank: true
  field :created_at, :date_time, null: false, auto_now_add: true
  field :updated_at, :date_time, null: false, auto_now: true

  db_unique_constraint :customer_unique_slug, field_names: [:slug]
end
