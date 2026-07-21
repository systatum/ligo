module Antrikan
  class Business < Marten::Model
    include ChangeTracker
    include SoftDeleter
    include IdConcealer

    field :id, :big_int, primary_key: true, auto: true
    field :name, :string, max_size: 255, null: false, blank: false
    field :created_at, :date_time, null: false, auto_now_add: true
    field :updated_at, :date_time, null: false, auto_now: true

    field :owner, :many_to_one, to: Auth::User, related: :businesses
  end
end
