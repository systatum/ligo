module Antrikan
  class SpaceReviewIndexHandler < RequestHandler
    include SpaceHelper

    protect_from_forgery false
    http_method_names :get

    def get : Marten::HTTP::Response
      with_deleted = request.query_params["with_deleted"]? == "true"

      reviews = with_deleted ? SpaceReview.unscoped : SpaceReview.all
      reviews = reviews.filter(space_id: space.id)

      result = reviews.map { |review| SpaceReviewSerializer.soft_serialize(review) }
      json({reviews: result}, status: 200)
    end
  end
end
