module Ligo
  class RealmCreateHandler < RequestHandler
    protect_from_forgery false
    http_method_names :post

    def post
      result = Realm::RegistrarService.new(request.data).run

      if result.success?
        json result.data.not_nil!, status: 200
      else
        render_invalid_payload(result.errors)
      end
    end
  end
end
