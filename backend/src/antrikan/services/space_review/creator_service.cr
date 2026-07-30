module Antrikan
  class SpaceReview::CreatorService < BaseService(SpaceReview)
    def initialize(@space : Space, @reviewer : Auth::User?, @data : Marten::HTTP::Params::Data)
    end

    def run : ServiceResult(SpaceReview)
      return failure(schema.errors) unless schema.valid?
      if @reviewer.nil? && !@space.allow_anonymous_reviewer?
        return failure(:reviewer, ErrorCode::SPACE_REVIEW_NOT_ANON_ALLOWED)
      end

      begin
        image_result = CarouselImagesResolverService.new(schema.images || [] of (JSON::Any | JSON::Serializable | Nil)).run
        return failure(image_result.errors) unless image_result.success?

        review = SpaceReview.new
        review.space = @space
        review.reviewer = @reviewer
        review.rating = schema.rating!
        review.review = schema.review if schema.review?
        review.channel = Channel.get_by_hashed_id!(schema.channel_id!) if schema.channel_id?
        review.item = Item.get_by_slug!(slug: schema.item_id!) if schema.item_id?
        review.image_ids = UploadedFileIds.new(ids: image_result.data.not_nil!)
        review.save!

        success(review)
      rescue ex : Marten::DB::Errors::InvalidRecord
        failure(ex.record.errors)
      end
    end

    private def schema
      @schema ||= SpaceReviewSchema.new(JsonArrayMapper.map(@data, "images"))
    end
  end
end
