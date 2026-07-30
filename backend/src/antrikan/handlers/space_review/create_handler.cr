module Antrikan
  class SpaceReviewCreateHandler < RequestHandler
    include SpaceHelper

    protect_from_forgery false
    http_method_names :post

    def post : Marten::HTTP::Response
      reviewer = space.allow_anonymous_reviewer? ? current_user : current_user!
      result = SpaceReview::CreatorService.new(space, reviewer, request.data).run

      if result.success?
        json SpaceReviewSerializer.serialize(result.data.not_nil!), status: 201
      else
        render_invalid_payload result.errors
      end
    end
  end
end
