class Workaty::EmployeeUpdateHandler < RequestHandler
  include EmployeeHelper

  protect_from_forgery false
  http_method_names :patch, :post

  def post
    patch
  end

  def patch
    authorize_employee_manipulation_request!

    if schema.valid?
      employee.update!(schema.validated_data)
      json Workaty::EmployeeSerializer.serialize(employee), status: 200
    else
      render_invalid_payload(schema)
    end
  rescue e
    handle_error(e)
  end
end
