class Antrikan::SpaceUpdateHandler < RequestHandler
  include Antrikan::SpaceHelper

  protect_from_forgery false
  http_method_names :patch, :post

  def post
    patch
  end

  def patch
    if schema.valid?
      space.update!(schema.validated_data)
      json Antrikan::SpaceSerializer.serialize(space), status: 200
    else
      render_invalid_payload(schema)
    end
  end
end
