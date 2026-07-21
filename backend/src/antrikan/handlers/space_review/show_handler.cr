module Antrikan
  class SpaceReviewShowHandler < RequestHandler
    include SpaceReviewHelper

    protect_from_forgery false
    http_method_names :get

    def get : Marten::HTTP::Response
      fetched_review = space_review
      sp = Space.unscoped.filter(id: fetched_review.space_id!).first
      raise Marten::HTTP::Errors::NotFound.new if sp.nil? || sp.deleted_at
      json SpaceReviewSerializer.serialize(fetched_review), status: 200
    end
  end
end
