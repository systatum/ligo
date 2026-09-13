module Ligo
  class BioUpdateHandler < RequestHandler
    protect_from_forgery false
    http_method_names :patch, :post

    def post
      patch
    end

    def patch
      raise AuthorizationError.new unless current_user

      form = FormPayload.new(request.body)

      result = User::BiodataUpdaterService.new(current_user!, form).run

      if result.success?
        json UserSerializer.serialize(result.data.not_nil!), status: 200
      else
        render_invalid_payload result.errors
      end
    end
  end
end
