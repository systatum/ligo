class Antrikan::SpaceShowHandler < RequestHandler
  include Antrikan::SpaceHelper

  protect_from_forgery false
  http_method_names :get

  def get
    raise Marten::HTTP::Errors::PermissionDenied.new unless owner_of_space?

    json Antrikan::SpaceSerializer.serialize(space), status: 200
  end
end
