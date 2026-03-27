module Auth
  class User::ProfilePictureUpdaterService < BaseService
    @schema : ProfilePictureUploadSchema?

    def initialize(@user : Auth::User, @data : Marten::HTTP::Params::Data)
    end

    def run : ServiceResult(UploadedFile)
      return ServiceResult(UploadedFile).failure(schema.errors) unless schema.valid?

      file = schema.validated_data["profile_picture"].as(Marten::HTTP::UploadedFile)

      # Persist the image to storage
      result = FileCommitterService.new(file).run
      result_data = result.data.not_nil!

      return ServiceResult(UploadedFile).failure(result.errors) unless result.success?

      begin
        @user.uploaded_profile_picture_file_id = result_data.id
        @user.save!

        ServiceResult(UploadedFile).success(result_data)
      rescue ex : Marten::DB::Errors::InvalidRecord
        ex.record.errors.each do |error|
          schema.errors.add(error.field.not_nil!, error.message)
        end
        ServiceResult(UploadedFile).failure(schema.errors)
      end
    end

    private def schema
      @schema ||= ProfilePictureUploadSchema.new(@data)
    end
  end
end
