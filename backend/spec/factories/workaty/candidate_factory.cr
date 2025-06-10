require "../user_factory"

def create_candidate(
  adder : Auth::User = create_user,
  fitness : Workaty::Candidate::Fitness = Workaty::Candidate::Fitness::UNKNOWN,
  first_name : String = "Steve",
  last_name : String = "Evets",
) : Workaty::Candidate
  cand = Workaty::Candidate.new
  cand.organization = adder.organization
  cand.first_name = first_name
  cand.last_name = last_name
  cand.fitness = fitness
  cand.save!

  cand
end
