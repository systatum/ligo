module Ligo
  class PasswordUpdateHandler < RequestHandler
    protect_from_forgery false
    http_method_names :post

    @schema : PasswordUpdateSchema?

    def post
      if schema.valid?
        user = schema.user.not_nil!
        user.set_password(schema.new_password!)
        user.save!

        json UserTokenSerializer.serialize(user)
      else
        render_invalid_payload(schema)
      end
    end

    private def schema : PasswordUpdateSchema
      @schema ||= PasswordUpdateSchema.new(request.data, current_user!)
    end
  end
end
