module Auth
  class SignUpHandler < RequestHandler
    @schema : SignUpSchema?

    http_method_names :post

    def post
      if schema.valid?
        user = User.new(email: schema.email!)
        user.organization = schema.organization
        user.first_name = schema.first_name
        user.last_name = schema.last_name
        user.role = Role::FULL_TIME_STAFF
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
