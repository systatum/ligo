module Antrikan
  class ItemUpdateHandler < RequestHandler
    include ItemHelper

    protect_from_forgery false
    http_method_names :patch, :post

    def post : Marten::HTTP::Response
      patch
    end

    def patch : Marten::HTTP::Response
      raise Marten::HTTP::Errors::PermissionDenied.new unless authorized_for_item?

      result = Item::UpdaterService.new(item, request.data).run

      if result.success?
        json ItemSerializer.serialize(result.data.not_nil!), status: 200
      else
        render_invalid_payload result.errors
      end
    end
  end
end
