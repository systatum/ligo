class Workaty::Degree < Marten::Model
  include IdConcealer
  include ChangeTracker
  include SoftDeleter

  enum Level
    VOCATIONAL
    BACHELOR
    MASTER
    DOCTORATE
    UNKNOWN
  end

  field :id, :big_int, primary_key: true, auto: true
  field :institution, :string, max_size: 255, null: false, blank: false
  field :level, :enum, values: Level, null: false, default: Level::UNKNOWN
  field :major_field, :string, max_size: 255, null: true, blank: true # ie. Computer Science
  field :obtained_at, :date, null: true, blank: true
  field :created_at, :date_time, null: false, auto_now_add: true
  field :updated_at, :date_time, null: false, auto_now: true

  field :candidate, :many_to_one, to: Workaty::Candidate, related: :degrees
end
