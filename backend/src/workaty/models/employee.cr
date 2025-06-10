class Workaty::Employee < Marten::Model
  include SlugGenerator
  include ChangeTracker
  include SoftDeleter

  field :id, :big_int, primary_key: true, auto: true
  field :slug, :string, max_size: 12, null: false, index: true, unique: true
  field :first_name, :string, max_size: 128, null: false, blank: false
  field :last_name, :string, max_size: 128, null: false, blank: true
  field :email, :string, max_size: 128, null: true, blank: true
  field :phone, :big_int, null: true, blank: true
  field :note, :text, null: true, blank: true
  field :created_at, :date_time, null: false, auto_now_add: true
  field :updated_at, :date_time, null: false, auto_now: true

  field :organization, :many_to_one, to: Auth::Organization, related: :employees
  field :team_divisions, :many_to_many, to: Workaty::TeamDivision, related: :members

  def add_team_divisions(*assigned_team_divisions : Workaty::TeamDivision)
    track_initial_record_values
    team_divisions.add(assigned_team_divisions)
    track_record_event(Changelog::ActionType::UPDATE)
  end
end
