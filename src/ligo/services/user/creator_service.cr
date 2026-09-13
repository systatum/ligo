module Ligo
  class User::CreatorService < BaseService(Ligo::User)
    @schema : SignUpSchema?

    def initialize(@data : Marten::HTTP::Params::Data)
    end

    def run : ServiceResult(Ligo::User)
      return failure(schema.errors) unless schema.valid?

      begin
        user = create_user
        success(user)
      rescue ex : Marten::DB::Errors::InvalidRecord
        failure(ex.record.errors)
      end
    end

    private def create_user
      user = User.new(email: schema.email!)
      user.organization = schema.organization
      user.first_name = schema.first_name
      user.last_name = schema.last_name
      user.role = schema.organization_name? ? schema.realm!.default_role! : Role::FULL_TIME_STAFF
      user.set_password(schema.password!)
      user.password_updated_at = Time.utc
      user.save!
      user
    end

    private def schema
      @schema ||= SignUpSchema.new(@data)
    end
  end
end
