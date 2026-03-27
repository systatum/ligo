module Antrikan
  class Space::UpdaterService < BaseService(Space)
    include Space::LogoUploader

    def initialize(@space : Space, @data : Marten::HTTP::Params::Data)
    end

    def run : ServiceResult(Space)
      return failure(schema.errors) unless schema.valid?

      begin
        handle_logo_upload

        @space.update!(schema.validated_data)

        success(@space)
      rescue ex : LogoUploadException
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
