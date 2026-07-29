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

    private def authorized_for_queuer?
      queuer.space!.owned_by?(current_user!)
    end

    private def authorized_for_queuer_including_deleted?
      queuer_including_deleted.space!.owned_by?(current_user!)
    end
  end
end
