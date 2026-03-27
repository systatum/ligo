module Antrikan
  class Space::CreatorService < BaseService(Space)
    include Space::LogoUploader

    def initialize(@user : Auth::User, @data : Marten::HTTP::Params::Data)
    end

    def run : ServiceResult(Space)
      return failure(schema.errors) unless schema.valid?

      begin
        handle_logo_upload

        space = Space.new(schema.validated_data)
        space.owner = @user
        space.save!

        success(space)
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
