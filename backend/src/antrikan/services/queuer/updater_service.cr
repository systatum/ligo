module Antrikan
  class Queuer::UpdaterService < BaseService(Queuer)
    def initialize(@space : Space, @data : Marten::HTTP::Params::Data)
    end

    def run : ServiceResult(Queuer)
      return failure(schema.errors) unless schema.valid?

      data = schema.validated_data

      queuer_id = data["queuer_id"].as(String)
      queuer = Queuer.filter_by_hashed_id(queuer_id).filter(space_id: @space.id).get!

      plain_password = data["password"].as(String)
      return failure(:password, "Password does not match") unless queuer.password_matches?(plain_password)

      begin
        queuer.name = data["name"].as(String) if @data.has_key?("name")

        if @data.has_key?("user_id")
          user_id_str = data["user_id"]?.as?(String)
          if user_id_str.nil? || user_id_str.empty?
            return failure(:user_id, "A registered user is required to queue in this space") if @space.require_registered_queuer!
            queuer.user = nil
          else
            user = Auth::User.filter_by_hashed_id(user_id_str).get!
            queuer.user = user
          end
        end

        queuer.save!
        success(queuer)
      rescue ex : Marten::DB::Errors::InvalidRecord
        failure(ex.record.errors)
      end
    end

    private def schema
      @schema ||= QueuerUpdateSchema.new(@data)
    end
  end
end
