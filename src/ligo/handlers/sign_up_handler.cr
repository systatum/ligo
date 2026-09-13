module Ligo
  class SignUpHandler < RequestHandler
    protect_from_forgery false
    http_method_names :post

    def post
      result = User::CreatorService.new(request.data).run
      if result.success?
        json UserSerializer.serialize(result.data.not_nil!), status: 200
      else
        render_invalid_payload result.errors
      end
    end
  end
end
