module Antrikan
  class Space::CreatorService < BaseService(Space)
    include FileUploader

    def initialize(@user : Auth::User, @data : Marten::HTTP::Params::Data)
    end

    def run : ServiceResult(Space)
      return failure(schema.errors) unless schema.valid?

      begin
        logo_file_id = upload_image(schema.logo)

        data = schema.validated_data
        data.delete("logo")
        data["logo_file_id"] = logo_file_id if logo_file_id

        space = Space.new(data)
        space.owner = @user
        space.save!

        success(space)
      rescue ex : ::Errors::LogoUploadException
        failure(ex.errors)
      rescue ex : Marten::DB::Errors::InvalidRecord
        failure(ex.record.errors)
      end
    end

    private def schema
      @schema ||= SpaceSchema.new(@data)
    end
  end
end
