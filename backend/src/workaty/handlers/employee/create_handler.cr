class Workaty::EmployeeCreateHandler < RequestHandler
  include Workaty::EmployeeHelper

  protect_from_forgery false
  http_method_names :post

  def post
    authorize_employee_manipulation_request!

    if schema.valid?
      employee = Workaty::Employee.new(schema.validated_data)
      employee.organization = current_user!.organization
      employee.save!
      json Workaty::EmployeeSerializer.serialize(employee), status: 200
    else
      render_invalid_payload(schema)
    end
  rescue e
    handle_error(e)
  end
end
