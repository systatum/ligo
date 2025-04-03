require "../user_factory"

def create_degree(
  candidate : Workaty::Candidate = create_candidate,
  institution = "University of Example",
  major_field = "Computer Science",
  level = Workaty::Degree::Level::BACHELOR,
  obtained_at : Time? = nil,
)
  degree = Workaty::Degree.new
  degree.candidate = candidate
  degree.institution = institution
  degree.level = level
  degree.major_field = major_field
  degree.obtained_at = obtained_at
  degree.save!

  degree
end
