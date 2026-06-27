module Antrikan
  class QueuedItemUpdateHandler < RequestHandler
    include QueuedItemHelper

    protect_from_forgery false
    http_method_names :patch, :post

    before_dispatch :require_authentication

    def patch
      post
    end

    def post : Marten::HTTP::Response
      result = QueuedItem::UpdaterService.new(
        current_user!.organization_id!.to_s,
        request.data
      ).run

      if result.success?
        serialized = result.data.not_nil!.map { |qi|
          QueuedItemSerializer.soft_serialize(qi)
        }
        json({items: serialized}, status: 200)
      else
        render_invalid_payload(result.errors)
      end
    end

    private def require_authentication
      raise Auth::AuthorizationError.new unless current_user
    end
  end
end
