class Workaty::EmployeeDeleteHandler < RequestHandler
  include EmployeeHelper

  protect_from_forgery false
  http_method_names :delete

  def delete
    authorize_employee_manipulation_request!

    employee.soft_delete!
    json Workaty::EmployeeSerializer.serialize(employee), status: 200
  rescue e
    handle_error(e)
  end
end
