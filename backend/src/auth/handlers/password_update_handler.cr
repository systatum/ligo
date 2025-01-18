require "./concerns/*"

module Auth
  class PasswordUpdateHandler < RequestHandler
    @schema : PasswordUpdateSchema?

    http_method_names :post

    def post
      if schema.valid?
        user = schema.user.not_nil!
        user.set_password(schema.new_password!)
        user.save!

        json UserTokenSerializer.serialize(user)
      else
        render_invalid_payload(schema)
      end
    rescue e
      handle_error(e)
    end

    private def schema : PasswordUpdateSchema
      @schema ||= begin
        schema = PasswordUpdateSchema.new(request.data)
        schema.user = current_user
        schema
      end
    end
  end
end
