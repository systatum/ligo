module Antrikan
  class QueuerCreateHandler < RequestHandler
    include SpaceHelper

    protect_from_forgery false
    http_method_names :post

    def post : Marten::HTTP::Response
      service = Queuer::CreatorService.new(space, request.data)
      result = service.run

      if result.success?
        data = result.data.not_nil!
        json({
          queuer:   QueuerSerializer.soft_serialize(data.queuer),
          password: data.generated_password,
        }, status: 201)
      else
        render_invalid_payload(result.errors)
      end
    end
  end
end
