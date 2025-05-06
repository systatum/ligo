class Workaty::DegreeCreateHandler < RequestHandler
  include Workaty::DegreeHelper

  protect_from_forgery false
  http_method_names :post

  def post
    authorize_degree_manipulation_request!

    if schema.valid?
      degree = Workaty::Degree.new(schema.validated_data)
      degree.candidate = candidate
      degree.save!
      json Workaty::DegreeSerializer.serialize(degree), status: 200
    else
      render_invalid_payload(schema)
    end
  rescue e
    handle_error(e)
  end
end
