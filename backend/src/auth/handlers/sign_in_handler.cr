module Auth
  class SignInHandler < RequestHandler
    @schema : SignInSchema?

    http_method_names :post

    def post
      if schema.valid?
        user = MartenAuth.authenticate(schema.email!, schema.password!)
        if user
          json UserTokenSerializer.serialize(user), status: 200
        else
          render_error 404, ["Invalid credentials"]
        end
      else
        render_invalid_payload
      end
    rescue e
      handle_error(e)
    end

    private def schema
      @schema ||= SignInSchema.new(request.data)
    end
  end
end
