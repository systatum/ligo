class Workaty::DegreeDeleteHandler < RequestHandler
  include Workaty::DegreeHelper

  protect_from_forgery false
  http_method_names :delete

  def delete
    authorize_degree_manipulation_request!

    degree.soft_delete!
    json Workaty::DegreeSerializer.serialize(degree), status: 200
  end
end
