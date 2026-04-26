module Antrikan
  module QueuerHelper
    @queuer : Queuer?

    private def queuer
      @queuer ||= Queuer
        .filter_by_hashed_id(params["queuer_hashed_id"].to_s)
        .get!
    end

    private def queuer_including_deleted
      @queuer ||= Queuer
        .filter_by_hashed_id(params["queuer_hashed_id"].to_s, unscoped: true)
        .get!
    end
  end
end
