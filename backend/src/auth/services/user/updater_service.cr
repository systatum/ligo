module Auth
  class User::UpdaterService < BaseService
    @schema : MyBioUpdateSchema?

    def initialize(@user : Auth::User, @payload : FormPayload)
    end

    def run : ServiceResult(Auth::User)
      unless schema.valid?
        return ServiceResult(Auth::User).failure(schema.errors)
      end

      begin
        update_fields
        ServiceResult(Auth::User).success(@user)
      rescue ex : Marten::DB::Errors::InvalidRecord
        ex.record.errors.each do |error|
          schema.errors.add(error.field.not_nil!, error.message)
        end
        ServiceResult(Auth::User).failure(schema.errors)
      end
    end

    private def update_fields
      @user.first_name = schema.first_name if schema.first_name?
      @user.last_name = schema.last_name if schema.last_name?
      @user.locale = schema.locale if schema.locale?
      @user.timezone_offset_seconds = schema.timezone_offset_seconds if schema.timezone_offset_seconds?

      @user.save!
    end

    private def schema
      @schema ||= MyBioUpdateSchema.new(@payload.to_validate)
    end
  end
end
