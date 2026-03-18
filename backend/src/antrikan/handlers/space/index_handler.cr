class Antrikan::SpaceIndexHandler < RequestHandler
  include Antrikan::SpaceHelper

  protect_from_forgery false
  http_method_names :get

  def get
    spaces = Antrikan::Space.filter(owner_id: current_user!.id, deleted_at: nil).map do |space|
      Antrikan::SpaceSerializer.soft_serialize(space)
    end
    json({
      spaces: spaces,
    }, status: 200)
  end
end
