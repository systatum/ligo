class Workaty::TeamDivision < Marten::Model
  include IdConcealer
  include ChangeTracker
  include SoftDeleter

  field :id, :big_int, primary_key: true, auto: true
  field :name, :string, max_size: 255, null: false, blank: false
  field :created_at, :date_time, null: false, auto_now_add: true
  field :updated_at, :date_time, null: false, auto_now: true

  field :organization, :many_to_one, to: Auth::Organization, related: :team_divisions
  field :leaders, :many_to_many, to: Workaty::Employee # a team division can have leaders

  def add_leaders(*assigned_leaders : Workaty::Employee)
    track_initial_record_values
    leaders.add(assigned_leaders)
    track_record_event(Changelog::ActionType::UPDATE)
  end
end
