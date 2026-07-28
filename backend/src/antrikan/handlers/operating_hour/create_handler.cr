class Antrikan::OperatingHourCreateHandler < RequestHandler
  include OperatingHourHelper

  protect_from_forgery false
  http_method_names :post

  def post
    raise Marten::HTTP::Errors::PermissionDenied.new unless owner?

    normalize_duration_params!

    if op_hour_schema.valid?
      op_hour = OperatingHour.new(op_hour_schema.validated_data)
      assign_operating_hour_owner!(op_hour)
      op_hour.save!
      json OperatingHourSerializer.serialize(op_hour), status: 201
    else
      render_invalid_payload(op_hour_schema)
    end
  end
end
