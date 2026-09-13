module Ligo
  class User::BiodataUpdaterService < BaseService(Ligo::User)
    @schema : BiodataUpdateSchema?

    def initialize(@user : Ligo::User, @payload : FormPayload)
    end

    def run : ServiceResult(Ligo::User)
      unless schema.valid?
        return failure(schema.errors)
      end

      begin
        update_fields
        success(@user)
      rescue ex : Marten::DB::Errors::InvalidRecord
        failure(ex.record.errors)
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
      @schema ||= BiodataUpdateSchema.new(@payload.to_validate)
    end
  end
end
