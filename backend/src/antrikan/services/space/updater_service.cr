module Antrikan
  class Space::UpdaterService < BaseService(Space)
    include FileUploader

    def initialize(@space : Space, @data : Marten::HTTP::Params::Data)
    end

    def run : ServiceResult(Space)
      return failure(schema.errors) unless schema.valid?

      begin
        logo_file_id = upload_image(schema.logo) if @data.has_key?("logo")

        if @data.has_key?("carousel_images")
          current_ids = @space.carousel_image_ids.try(&.ids) || [] of String
          result = CarouselImagesResolverService.new(schema.carousel_images!, current_ids).run
          return failure(result.errors) unless result.success?
          new_ids = result.data
        end

        data = schema.validated_data
        data.delete("logo")
        data.delete("business_name")
        data.delete("carousel_images")
        data["logo_file_id"] = logo_file_id if @data.has_key?("logo") && logo_file_id

        @space.carousel_image_ids = UploadedFileIds.new(ids: new_ids) if new_ids
        @space.update!(data)

        success(@space)
      rescue ex : ::Errors::LogoUploadException
        failure(ex.errors)
      rescue ex : Marten::DB::Errors::InvalidRecord
        failure(ex.record.errors)
      end
    end

    private def schema
      @schema ||= SpaceSchema.new(JsonArrayMapper.map(@data, "carousel_images"))
    end
  end
end
