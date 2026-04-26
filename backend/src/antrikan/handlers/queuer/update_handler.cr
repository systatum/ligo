module Antrikan
  class QueuerUpdateHandler < RequestHandler
    include SpaceHelper

    protect_from_forgery false
    http_method_names :patch, :post

    def post : Marten::HTTP::Response
      patch
    end

    def patch : Marten::HTTP::Response
      result = Queuer::UpdaterService.new(space, request.data).run

      if result.success?
        json QueuerSerializer.serialize(result.data.not_nil!), status: 200
      else
        render_invalid_payload(result.errors)
      end
    end
  end
end
