module Ligo
  class SignInHandler < RequestHandler
    protect_from_forgery false
    http_method_names :post

    @schema : SignInSchema?

    def post
      if schema.valid?
        user = MartenAuth.authenticate(schema.email!, schema.password!)
        if user
          unless user.is_email_address_verified?
            return render_error 403, ["Email address not verified"]
          end
          json UserTokenSerializer.serialize(user), status: 200
        else
          render_error 404, ["Invalid credentials"]
        end
      else
        render_invalid_payload(schema)
      end
    end

    private def schema
      @schema ||= SignInSchema.new(request.data)
    end
  end
end
