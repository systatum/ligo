class Antrikan::SpaceCreateHandler < RequestHandler
  include Antrikan::SpaceHelper

  protect_from_forgery false
  http_method_names :post

  def post
    if schema.valid?
      space = Antrikan::Space.new(schema.validated_data)
      space.owner = current_user!
      space.save!
      json Antrikan::SpaceSerializer.serialize(space), status: 201
    else
      render_invalid_payload(schema)
    end
  end
end
