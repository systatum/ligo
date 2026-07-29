module Antrikan
  class QueuerIndexHandler < RequestHandler
    include SpaceHelper

    protect_from_forgery false
    http_method_names :get

    def get : Marten::HTTP::Response
      with_deleted = request.query_params["with_deleted"]? == "true"

      queuers = with_deleted ? Queuer.unscoped : Queuer.all
      queuers = queuers.filter(space_id: space.id)

      result = queuers.map { |q| QueuerSerializer.soft_serialize(q) }
      json(result, status: 200)
    end
  end
end
