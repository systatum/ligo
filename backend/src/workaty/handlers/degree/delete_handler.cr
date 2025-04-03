class Workaty::DegreeDeleteHandler < RequestHandler
  include Workaty::DegreeHelper

  http_method_names :delete

  def delete
    authorize_degree_manipulation_request!

    degree.soft_delete!
    json Workaty::DegreeSerializer.serialize(degree), status: 200
  rescue e
    handle_error(e)
  end
end
