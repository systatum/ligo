class Antrikan::SpaceCreateHandler < RequestHandler
  include Antrikan::SpaceHelper

  protect_from_forgery false
  http_method_names :post

  def post
    result = Space::CreatorService.new(current_user!, request.data).run

    if result.success?
      json Antrikan::SpaceSerializer.serialize(result.data.not_nil!), status: 201
    else
      render_invalid_payload(result.errors)
    end
  end
end
