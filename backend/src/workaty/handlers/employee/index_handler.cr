class Workaty::EmployeeIndexHandler < RequestHandler
  include EmployeeHelper

  protect_from_forgery false
  http_method_names :get

  def get
    authorize_employee_manipulation_request!

    employees = Employee.filter(organization: current_organization!).map do |employee|
      EmployeeSerializer.soft_serialize(employee)
    end

    team_divisions = TeamDivision.filter(organization: current_organization!).map do |team_division|
      TeamDivisionSerializer.soft_serialize(team_division)
    end

    json({
      employees:      employees,
      team_divisions: team_divisions,
    }, status: 200)
  end
end
