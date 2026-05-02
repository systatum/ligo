module Antrikan
  class ItemUndeleteHandler < RequestHandler
    include ItemHelper

    protect_from_forgery false
    http_method_names :patch, :post

    def post : Marten::HTTP::Response
      patch
    end

    def patch : Marten::HTTP::Response
      raise Marten::HTTP::Errors::PermissionDenied.new unless current_user!.admin?

      it = item_even_if_deleted
      it.deleted_at = nil
      it.save!
      json ItemSerializer.serialize(it), status: 200
    end
  end
end
