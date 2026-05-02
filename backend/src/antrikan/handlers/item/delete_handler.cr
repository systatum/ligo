module Antrikan
  class ItemDeleteHandler < RequestHandler
    include ItemHelper

    protect_from_forgery false
    http_method_names :delete

    def delete : Marten::HTTP::Response
      raise Marten::HTTP::Errors::PermissionDenied.new unless current_user!.admin?

      item.soft_delete!
      json ItemSerializer.serialize(item), status: 200
    end
  end
end
