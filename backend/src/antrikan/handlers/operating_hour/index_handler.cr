class Antrikan::OperatingHourIndexHandler < RequestHandler
  include SpaceHelper
  include OperatingHourHelper

  protect_from_forgery false
  http_method_names :get

  def get
    op_hours = OperatingHour.filter(space_id: space.id, deleted_at: nil).map do |op_hour|
      OperatingHourSerializer.soft_serialize(op_hour)
    end
    json({
      op_hours: op_hours,
    }, status: 200)
  end
end
