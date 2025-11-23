module Auth
  class SignUpHandler < RequestHandler
    protect_from_forgery false
    http_method_names :post

    @schema : SignUpSchema?

    def post
      # todo: same user of same organization can't be created
      if schema.valid?
        user = User.new(email: schema.email!)
        user.organization = schema.organization
        user.first_name = schema.first_name
        user.last_name = schema.last_name
        user.role = Auth::Role::FULL_TIME_STAFF
        user.set_password(schema.password!)
        user.password_updated_at = Time.utc
        user.save!

        json UserSerializer.serialize(user), status: 200
      else
        render_invalid_payload schema
      end
    end

    private def schema
      @schema ||= SignUpSchema.new(request.data)
    end
  end
end
