module Antrikan
  record QueuerCreationResult, queuer : Queuer, generated_password : String

  class Queuer::CreatorService < BaseService(QueuerCreationResult)
    def initialize(@space : Space, @data : Marten::HTTP::Params::Data)
    end

    def run : ServiceResult(QueuerCreationResult)
      return failure(schema.errors) unless schema.valid?

      if !schema.user_id? && @space.require_registered_queuer!
        return failure(:user_id, "A registered user is required to queue in this space")
      end

      begin
        plain_password = Random::Secure.hex(16)
        queuer = create_queuer(plain_password)

        result = QueuerCreationResult.new(queuer, plain_password)
        success(result)
      rescue ex : Marten::DB::Errors::InvalidRecord
        failure(ex.record.errors)
      rescue ex : Marten::DB::Errors::RecordNotFound
        failure(:user_id, "User not found")
      end
    end

    private def create_queuer(password : String)
      queuer = Queuer.new
      queuer.space = @space
      queuer.name = schema.name!
      queuer.home_address = schema.home_address if schema.home_address?
      queuer.mobile_phone = schema.mobile_phone if schema.mobile_phone?
      queuer.note = schema.note if schema.note?
      queuer.password = password

      if schema.user_id?
        user = Auth::User.filter_by_hashed_id(schema.user_id!).get!
        queuer.user = user
      end

      queuer.save!

      queuer
    end

    private def schema
      @schema ||= QueuerSchema.new(@data)
    end
  end
end
