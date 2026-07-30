module Antrikan
  class SpaceReview::UpdaterService < BaseService(SpaceReview)
    def initialize(@space_review : SpaceReview, @data : Marten::HTTP::Params::Data)
    end

    def run : ServiceResult(SpaceReview)
      return failure(schema.errors) unless schema.valid?

      begin
        if @data.has_key?("images")
          current_ids = @space_review.image_ids.try(&.ids) || [] of String
          image_result = CarouselImagesResolverService.new(schema.images!, current_ids).run
          return failure(image_result.errors) unless image_result.success?
          @space_review.image_ids = UploadedFileIds.new(ids: image_result.data.not_nil!)
        end

        @space_review.rating = schema.rating if schema.rating?
        @space_review.review = schema.review if @data.has_key?("review")
        @space_review.channel = Channel.get_by_hashed_id!(schema.channel_id!) if schema.channel_id?
        @space_review.item = Item.get_by_slug!(slug: schema.item_id!) if schema.item_id?
        @space_review.save!

        success(@space_review)
      rescue ex : Marten::DB::Errors::InvalidRecord
        failure(ex.record.errors)
      end
    end

    private def schema
      @schema ||= SpaceReviewUpdateSchema.new(JsonArrayMapper.map(@data, "images"))
    end
  end
end
