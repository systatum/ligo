module Antrikan
  class Queuer::UpdaterService < BaseService(Queuer)
    def initialize(@space : Space, @data : Marten::HTTP::Params::Data)
    end

    def run : ServiceResult(Queuer)
      return failure(schema.errors) unless schema.valid?

      queuer = Queuer
        .filter_by_hashed_id(schema.queuer_id!)
        .filter(space_id: @space.id)
        .get!

      unless queuer.password_matches?(schema.password!)
        return failure(:password, "Password does not match")
      end

      if @data.has_key?("user_id") && !schema.user_id? && @space.require_registered_queuer!
        return failure(:user_id, "A registered user is required to queue in this space")
      end

      begin
        update_fields(queuer)
        success(queuer)
      rescue ex : Marten::DB::Errors::InvalidRecord
        failure(ex.record.errors)
      end
    end

    private def update_fields(queuer : Queuer)
      queuer.name = schema.name if schema.name?
      queuer.home_address = schema.home_address.try(&.strip.presence)
      queuer.mobile_phone = schema.mobile_phone.try(&.strip.presence)
      queuer.note = schema.note.try(&.strip.presence)

      if @data.has_key?("user_id")
        if schema.user_id?
          user = Auth::User.filter_by_hashed_id(schema.user_id!).get!
          queuer.user = user
        else
          queuer.user = nil
        end
      end

      queuer.save!
    end

    private def schema
      @schema ||= QueuerUpdateSchema.new(@data)
    end
  end
end
