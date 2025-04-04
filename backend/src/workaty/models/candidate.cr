class Workaty::Candidate < Marten::Model
  include SlugGenerator
  include ChangeTracker
  include SoftDeleter

  # Fitness may even be reflected later. Such as, the candidate is hired,
  # but then known to be a bad fit for the job later on. So, this doesn't
  # indicate at which stage a candidate currently is.
  enum Fitness
    UNKNOWN
    GOOD_FIT
    BAD_FIT
  end

  field :id, :big_int, primary_key: true, auto: true
  field :slug, :string, max_size: 12, null: false, index: true, unique: true
  field :first_name, :string, max_size: 128, null: false, blank: false
  field :last_name, :string, max_size: 128, null: false, blank: true
  field :fitness, :enum, values: Fitness, null: false, default: Fitness::UNKNOWN
  field :note, :text, null: true, blank: true
  field :created_at, :date_time, null: false, auto_now_add: true
  field :updated_at, :date_time, null: false, auto_now: true

  field :organization, :many_to_one, to: Auth::Organization, related: :candidates
end
