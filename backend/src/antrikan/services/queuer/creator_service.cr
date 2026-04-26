module Antrikan
  record QueuerCreationResult, queuer : Queuer, generated_password : String

  class Queuer::CreatorService < BaseService(QueuerCreationResult)
    def initialize(@space : Space, @data : Marten::HTTP::Params::Data)
    end

    def run : ServiceResult(QueuerCreationResult)
      return failure(schema.errors) unless schema.valid?

      begin
        data = schema.validated_data

        plain_password = Random::Secure.hex(16)

        queuer = Queuer.new
        queuer.space = @space
        queuer.name = data["name"].as(String)
        queuer.password = plain_password

        user_id_str = data["user_id"]?.as?(String)

        if @space.require_registered_queuer! && (user_id_str.nil? || user_id_str.empty?)
          return failure(:user_id, "A registered user is required to queue in this space")
        end

        if user_id_str && !user_id_str.empty?
          user = Auth::User.filter_by_hashed_id(user_id_str).get!
          queuer.user = user
        end

        queuer.save!

        success(QueuerCreationResult.new(queuer, plain_password))
      rescue ex : Marten::DB::Errors::InvalidRecord
        failure(ex.record.errors)
      end
    end

    private def schema
      @schema ||= QueuerSchema.new(@data)
    end
  end
end
