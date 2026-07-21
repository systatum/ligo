module Antrikan
  class Space::CreatorService < BaseService(Space)
    include FileUploader

    def initialize(@user : Auth::User, @data : Marten::HTTP::Params::Data)
    end

    def run : ServiceResult(Space)
      return failure(schema.errors) unless schema.valid?

      begin
        logo_file_id = upload_image(schema.logo)
        business_name = schema.business_name? ? schema.business_name! : schema.name!

        carousel_image_ids = if schema.carousel_images?
                               ids = [] of String

                               schema.carousel_images!.each do |entry|
                                 item = entry.as(SpaceSchema::CarouselImagePayload)

                                 if item.keep_id
                                   return failure(:carousel_images, "cannot keep an existing image when creating a new space")
                                 end

                                 raw_payload = FilePayload.from_json({base64_bytes: item.base64_bytes, mimetype: item.mimetype}.to_json)
                                 ids << upload_image(raw_payload).not_nil!.to_s
                               end

                               ids
                             end

        data = schema.validated_data
        data.delete("logo")
        data.delete("business_name")
        data.delete("carousel_images")
        data["logo_file_id"] = logo_file_id if logo_file_id

        business = Business.create!(name: business_name, owner: @user)

        space = Space.new(data)
        space.manager = @user
        space.owner = business
        space.carousel_image_ids = CarouselImageIds.new(ids: carousel_image_ids) if carousel_image_ids
        space.save!

        success(space)
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
