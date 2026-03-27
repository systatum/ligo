module Antrikan
  class Space::MemberRegisterService < BaseService(SpaceJoinResult)
    @schema : SpaceJoinSchema?
    @normalized_data : Marten::Schema::AnyDataHash?

    def initialize(@space : Antrikan::Space, @data : Marten::HTTP::Params::Data)
    end

    def run : ServiceResult(SpaceJoinResult)
      return failure(schema.errors) unless schema.valid?

      users = schema.users
      return success(SpaceJoinResult.new) if users.nil?

      added = [] of Auth::User
      failed = [] of Auth::User
      invalid_ids = [] of String

      hashed_user_ids = unique_hashed_user_ids_from(users)
      users_by_hashed_id = Auth::User.index_by_hashed_ids(hashed_user_ids)

      users_to_add = [] of Auth::User

      hashed_user_ids.each do |user_id|
        user = users_by_hashed_id[user_id]?
        if user.nil?
          decoded_id = IdConcealer.decode(user_id)
          if decoded_id.nil?
            invalid_ids << user_id
            next
          end

          failed << Auth::User.new(id: decoded_id.to_i64)
          next
        end

        users_to_add << user
      end

      unless users_to_add.empty?
        begin
          @space.members.add(users_to_add)
          added.concat(users_to_add)
        rescue
          # Fallback to per-member addition if batch insert fails unexpectedly
          users_to_add.each do |user|
            begin
              @space.members.add(user)
              added << user
            rescue
              failed << user
            end
          end
        end
      end

      success(SpaceJoinResult.new(added, failed, invalid_ids))
    end

    private def unique_hashed_user_ids_from(users) : Set(String)
      user_ids = Set(String).new

      users.each do |entry|
        entry = entry.as(SpaceJoinUserPayload)
        user_ids.add(entry.user_id)
      end

      user_ids
    end

    private def schema
      @schema ||= SpaceJoinSchema.new(normalized_data)
    end

    # Marten stores JSON arrays in Params::Data as a single JSON::Any entry.
    # The schema array field expects each array element as an individual value,
    # so we flatten users when it is a JSON array payload.
    private def normalized_data : Marten::Schema::AnyDataHash
      @normalized_data ||= begin
        users = @data["users"]?
        users_json = users.as?(JSON::Any)
        return @data if users_json.nil?

        return @data unless users_json.raw.as?(Array)

        normalized_params = Marten::HTTP::Params::Data::RawHash.new
        @data.each do |key, values|
          if key == "users"
            normalized_users = [] of Marten::HTTP::Params::Data::Value
            users_json.as_a.each do |entry|
              normalized_users << entry
            end
            normalized_params[key] = normalized_users
          else
            normalized_params[key] = values
          end
        end

        Marten::HTTP::Params::Data.new(normalized_params)
      end
    end
  end
end
