module Auth
  class SignInHandler < RequestHandler
    protect_from_forgery false
    http_method_names :post

    @schema : SignInSchema?

    def post
      if schema.valid?
        user = MartenAuth.authenticate(schema.email!, schema.password!)
        if user
          json UserTokenSerializer.serialize(user), status: 200
        else
          render_error 404, ["Invalid credentials"]
        end
      else
        render_invalid_payload(schema)
      end
    rescue e
      handle_error(e)
    end

    private def schema
      @schema ||= SignInSchema.new(request.data)
    end
  end
end
