module Ligo
  class User::ProfilePictureUpdaterService < BaseService(UploadedFile)
    @schema : ProfilePictureUploadSchema?

    def initialize(@user : Ligo::User, @data : Marten::HTTP::Params::Data)
    end

    def run : ServiceResult(UploadedFile)
      return failure(schema.errors) unless schema.valid?

      file = schema.validated_data["profile_picture"].as(Marten::HTTP::UploadedFile)

      result = FileCommitterService.new(file).run

      return failure(result.errors) unless result.success?

      begin
        result_data = result.data.not_nil!
        @user.uploaded_profile_picture_file_id = result_data.id
        @user.save!

        success(result_data)
      rescue ex : Marten::DB::Errors::InvalidRecord
        failure(ex.record.errors)
      end
    end

    private def schema
      @schema ||= ProfilePictureUploadSchema.new(@data)
    end
  end
end
