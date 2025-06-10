require "../user_factory"

def create_employee(
  adder : Auth::User = create_user,
  first_name : String = "Steve",
  last_name : String? = "Evets",
  email : String? = "#{Random.new.urlsafe_base64(10)}@example.com",
  phone : Int64? = 81529891111,
  note : String? = nil,
  team_division : Workaty::TeamDivision? = nil,
) : Workaty::Employee
  emp = Workaty::Employee.new
  emp.organization = adder.organization
  emp.first_name = first_name
  emp.last_name = last_name
  emp.email = email
  emp.phone = phone
  emp.note = note
  emp.save!

  if team_division
    emp.add_team_divisions(team_division)
  end

  emp
end
