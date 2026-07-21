module Antrikan
  class SpaceReviewUpdateHandler < RequestHandler
    include SpaceReviewHelper

    protect_from_forgery false
    http_method_names :patch, :post

    def post : Marten::HTTP::Response
      patch
    end

    def patch : Marten::HTTP::Response
      raise Marten::HTTP::Errors::PermissionDenied.new unless authorized_to_edit_review?

      result = SpaceReview::UpdaterService.new(space_review, request.data).run

      if result.success?
        json SpaceReviewSerializer.serialize(result.data.not_nil!), status: 200
      else
        render_invalid_payload result.errors
      end
    end
  end
end
