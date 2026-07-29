class Antrikan::OperatingHourIndexHandler < RequestHandler
  include OperatingHourHelper

  protect_from_forgery false
  http_method_names :get

  def get
    raise Marten::HTTP::Errors::PermissionDenied.new unless owner?

    op_hours = op_hour_scope.map do |op_hour|
      OperatingHourSerializer.soft_serialize(op_hour)
    end
    json({
      op_hours: op_hours,
    }, status: 200)
  end
end
