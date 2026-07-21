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
          new_ids = [] of String

          schema.carousel_images!.each do |entry|
            item = entry.as(SpaceSchema::CarouselImagePayload)

            if (keep_id = item.keep_id)
              unless current_ids.includes?(keep_id)
                return failure(:carousel_images, "keep_id does not reference an existing image on this space")
              end
              new_ids << keep_id
            else
              raw_payload = FilePayload.from_json({base64_bytes: item.base64_bytes, mimetype: item.mimetype}.to_json)
              new_ids << upload_image(raw_payload).not_nil!.to_s
            end
          end
        end

        data = schema.validated_data
        data.delete("logo")
        data.delete("business_name")
        data.delete("carousel_images")
        data["logo_file_id"] = logo_file_id if @data.has_key?("logo") && logo_file_id

        @space.carousel_image_ids = CarouselImageIds.new(ids: new_ids) if new_ids
        @space.update!(data)

        success(@space)
      rescue ex : ::Errors::LogoUploadException
        failure(ex.errors)
      rescue ex : Marten::DB::Errors::InvalidRecord
        failure(ex.record.errors)
      end
    end

    private def schema
      @schema ||= SpaceSchema.new(JsonArrayFieldNormalizer.normalize(@data, "carousel_images"))
    end
  end
end
