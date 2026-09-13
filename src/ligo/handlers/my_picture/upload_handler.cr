module Ligo
  class MyPictureUploadHandler < RequestHandler
    protect_from_forgery false
    http_method_names :post, :patch

    def post
      patch
    end

    def patch
      raise AuthorizationError.new unless current_user

      result = User::ProfilePictureUpdaterService.new(current_user!, request.data).run

      if result.success?
        json UploadedFileSerializer.serialize(result.data.not_nil!), status: 200
      else
        render_invalid_payload result.errors
      end
    end
  end
end
