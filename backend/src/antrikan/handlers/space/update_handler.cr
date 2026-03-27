class Antrikan::SpaceUpdateHandler < RequestHandler
  include Antrikan::SpaceHelper

  protect_from_forgery false
  http_method_names :patch, :post

  def post
    patch
  end

  def patch
    raise Marten::HTTP::Errors::PermissionDenied.new unless owner_of_space?

    result = Space::UpdaterService.new(space, request.data).run

    if result.success?
      json Antrikan::SpaceSerializer.serialize(result.data.not_nil!), status: 200
    else
      render_invalid_payload result.errors
    end
  end
end
