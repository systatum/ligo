module Antrikan
  class SpaceReviewCreateHandler < RequestHandler
    include SpaceHelper

    protect_from_forgery false
    http_method_names :post

    def post : Marten::HTTP::Response
      result = SpaceReview::CreatorService.new(space, current_user!, request.data).run

      if result.success?
        json SpaceReviewSerializer.serialize(result.data.not_nil!), status: 201
      else
        render_invalid_payload result.errors
      end
    end
  end
end
