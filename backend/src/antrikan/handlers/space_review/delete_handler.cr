module Antrikan
  class SpaceReviewDeleteHandler < RequestHandler
    include SpaceReviewHelper

    protect_from_forgery false
    http_method_names :delete

    def delete : Marten::HTTP::Response
      raise Marten::HTTP::Errors::PermissionDenied.new unless authorized_to_delete_review?

      space_review.soft_delete!
      json SpaceReviewSerializer.serialize(space_review), status: 200
    end
  end
end
