class Antrikan::SpaceDeleteHandler < RequestHandler
  include Antrikan::SpaceHelper

  protect_from_forgery false
  http_method_names :delete

  def delete
    raise Marten::HTTP::Errors::PermissionDenied.new unless owner_of_space?

    space.soft_delete!
    json Antrikan::SpaceSerializer.serialize(space), status: 200
  end
end
