class Antrikan::SpaceDeleteHandler < RequestHandler
  include Antrikan::SpaceHelper

  protect_from_forgery false
  http_method_names :delete

  def delete
    space.soft_delete!
    json Antrikan::SpaceSerializer.serialize(space), status: 200
  end
end
