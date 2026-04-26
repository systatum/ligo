module Antrikan
  class QueuerDeleteHandler < RequestHandler
    include QueuerHelper

    protect_from_forgery false
    http_method_names :delete

    def delete : Marten::HTTP::Response
      raise Marten::HTTP::Errors::PermissionDenied.new unless current_user!.admin?
      raise Marten::HTTP::Errors::PermissionDenied.new unless queuer.space!.owner == current_user!

      queuer.soft_delete!
      json QueuerSerializer.serialize(queuer), status: 200
    end
  end
end
