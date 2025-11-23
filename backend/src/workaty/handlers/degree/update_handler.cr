class Workaty::DegreeUpdateHandler < RequestHandler
  include Workaty::DegreeHelper

  protect_from_forgery false
  http_method_names :patch, :post

  def post
    patch
  end

  def patch
    authorize_degree_manipulation_request!

    if schema.valid?
      degree.update!(schema.validated_data)
      json Workaty::DegreeSerializer.serialize(degree), status: 200
    else
      render_invalid_payload(schema)
    end
  end
end
