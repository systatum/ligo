module Ligo
  class PasswordResetConfirmHandler < RequestHandler
    protect_from_forgery false
    http_method_names :post

    @schema : PasswordResetConfirmSchema?

    def post
      if schema.valid?
        user = schema.user.not_nil!
        user.set_password(schema.password1!)
        user.reset_password_token = nil
        user.reset_password_token_created_at = nil
        user.save!

        json UserTokenSerializer.serialize(user)
      else
        render_invalid_payload(schema)
      end
    end

    private def schema
      @schema ||= PasswordResetConfirmSchema.new(request.data)
    end
  end
end
