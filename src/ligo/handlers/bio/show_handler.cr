module Ligo
  class BioShowHandler < RequestHandler
    protect_from_forgery false
    http_method_names :get

    def get : Marten::HTTP::Response
      only = request.query_params["only"]?.presence

      return json fetch_others(only), status: 200 if only

      raise AuthorizationError.new unless current_user

      json UserSerializer.serialize(current_user!), status: 200
    end

    private def fetch_others(only : String)
      hashed_ids = only.split(",").map(&.strip).reject(&.empty?)
      users_by_hashed_id = Ligo::User.index_by_hashed_ids(hashed_ids.to_set)

      hashed_ids.compact_map { |hashed_id| users_by_hashed_id[hashed_id]? }
        .map { |user| PublicUserSerializer.soft_serialize(user) }
    end
  end
end
