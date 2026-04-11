module Antrikan
  class Space::UpdaterService < BaseService(Space)
    include FileUploader

    def initialize(@space : Space, @data : Marten::HTTP::Params::Data)
    end

    def run : ServiceResult(Space)
      return failure(schema.errors) unless schema.valid?

      begin
        logo_file_id = upload_image(schema.logo) if @data.has_key?("logo")

        data = schema.validated_data
        data.delete("logo")
        data["logo_file_id"] = logo_file_id if @data.has_key?("logo") && logo_file_id

        @space.update!(data)

        success(@space)
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
