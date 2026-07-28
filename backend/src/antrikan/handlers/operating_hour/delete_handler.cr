class Antrikan::OperatingHourDeleteHandler < RequestHandler
  include OperatingHourHelper

  protect_from_forgery false
  http_method_names :delete

  def delete
    raise Marten::HTTP::Errors::PermissionDenied.new unless owner?

    op_hour.soft_delete!
    json OperatingHourSerializer.serialize(op_hour), status: 200
  end
end
