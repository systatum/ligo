require "../user_factory"

def create_team_division(
  adder : Auth::User = create_user,
  name : String = "HR"
)
  team_division = Workaty::TeamDivision.new
  team_division.organization = adder.organization
  team_division.name = name
  team_division.save!

  team_division
end
