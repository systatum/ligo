module Antrikan
  class QueuerUndeleteHandler < RequestHandler
    include QueuerHelper

    protect_from_forgery false
    http_method_names :patch, :post

    def post : Marten::HTTP::Response
      patch
    end

    def patch : Marten::HTTP::Response
      raise Marten::HTTP::Errors::PermissionDenied.new unless current_user!.admin?
      raise Marten::HTTP::Errors::PermissionDenied.new unless authorized_for_queuer_including_deleted?

      q = queuer_including_deleted
      q.deleted_at = nil
      q.save!
      json QueuerSerializer.serialize(q), status: 200
    end
  end
end
