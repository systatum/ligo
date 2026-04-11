module Antrikan
  class Channel < Marten::Model
    include ChangeTracker
    include SoftDeleter
    include IdConcealer

    field :id, :big_int, primary_key: true, auto: true
    field :space, :many_to_one, to: Antrikan::Space, related: :channels
    field :name, :string, max_size: 255, null: false, blank: false
    field :logo_file_id, :uuid, null: true, blank: true
    field :description, :text, null: true, blank: true
    field :created_at, :date_time, null: false, auto_now_add: true
    field :updated_at, :date_time, null: false, auto_now: true
  end
end
