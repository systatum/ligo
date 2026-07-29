module Antrikan
  class SpaceReview::CreatorService < BaseService(SpaceReview)
    def initialize(@space : Space, @reviewer : Auth::User, @data : Marten::HTTP::Params::Data)
    end

    def run : ServiceResult(SpaceReview)
      return failure(schema.errors) unless schema.valid?

      begin
        review = SpaceReview.new
        review.space = @space
        review.reviewer = @reviewer
        review.rating = schema.rating!
        review.review = schema.review if schema.review?
        review.save!

        success(review)
      rescue ex : Marten::DB::Errors::InvalidRecord
        failure(ex.record.errors)
      end
    end

    private def schema
      @schema ||= SpaceReviewSchema.new(@data)
    end
  end
end
