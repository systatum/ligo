module Antrikan
  class Item < Marten::Model
    include SlugGenerator
    include ChangeTracker
    include SoftDeleter

    field :id, :big_int, primary_key: true, auto: true
    field :channel, :many_to_one, to: Antrikan::Channel, related: :items
    field :slug, :string, max_size: 6, null: false, index: true, unique: true
    field :name, :string, max_size: 255, null: false, blank: false
    field :order, :int, null: false, default: 0
    field :daily_cap, :int, null: false, default: 0 # daily capacity since the channel's operating hour, if negative means no cap
    field :unit_price, :big_int, null: false, default: 0
    field :unit_currency, :int, null: false, default: Currency::IDR.value
    field :is_monitored, :bool, null: false, default: false # if true, then new user purchasing this needs to be specifically acknowledged before being confirmed
    field :description, :text, null: true, blank: true
    field :main_image_file_id, :uuid, null: true, blank: true
    field :created_at, :date_time, null: false, auto_now_add: true
    field :updated_at, :date_time, null: false, auto_now: true
  end
end
