module Workaty::EmployeeHelper
  @employee : Workaty::Employee?
  @schema : Workaty::EmployeeSchema?

  def self.authorize_employee_manipulation_request!(current_user : Auth::User?)
    return false unless current_user

    role = current_user.role!
    can = Auth::Role.at_least_chief_staff?(current_user) ||
          Auth::Role.hr_staff?(current_user)

    raise Auth::AuthorizationError.new unless can
  end

  def authorize_employee_manipulation_request!
    Workaty::EmployeeHelper.authorize_employee_manipulation_request!(current_user)
  end

  private def employee
    @employee ||= Workaty::Employee
      .filter_by_slug(params["employee_slug"].to_s)
      .get!(organization_id: current_user!.organization_id)
  end

  private def schema
    @schema ||= Workaty::EmployeeSchema.new(request.data, current_user!)
  end
end
