class Antrikan::OperatingHourUpdateHandler < RequestHandler
  include OperatingHourHelper

  protect_from_forgery false
  http_method_names :patch, :post

  def post
    patch
  end

  def patch
    raise Marten::HTTP::Errors::PermissionDenied.new unless owner?

    normalize_duration_params!

    if op_hour_schema.valid?
      op_hour.update!(op_hour_schema.validated_data)
      json OperatingHourSerializer.serialize(op_hour), status: 200
    else
      render_invalid_payload(op_hour_schema)
    end
  end
end
