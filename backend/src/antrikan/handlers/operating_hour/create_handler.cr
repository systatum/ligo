class Antrikan::OperatingHourCreateHandler < RequestHandler
  include SpaceHelper
  include OperatingHourHelper

  protect_from_forgery false
  http_method_names :post

  def post
    normalize_duration_params!

    if op_hour_schema.valid?
      op_hour = OperatingHour.new(op_hour_schema.validated_data)
      op_hour.space = space
      op_hour.save!
      json OperatingHourSerializer.serialize(op_hour), status: 201
    else
      render_invalid_payload(op_hour_schema)
    end
  end
end
