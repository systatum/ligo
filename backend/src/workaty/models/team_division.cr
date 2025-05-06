class Workaty::TeamDivision < Marten::Model
  include IdConcealer
  include ChangeTracker
  include SoftDeleter

  field :id, :big_int, primary_key: true, auto: true
  field :name, :string, max_size: 255, null: false, blank: false
  field :created_at, :date_time, null: false, auto_now_add: true
  field :updated_at, :date_time, null: false, auto_now: true
  field :organization, :many_to_one, to: Auth::Organization, related: :team_divisions
end
