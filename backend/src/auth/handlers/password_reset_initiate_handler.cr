require "./concerns/*"

module Auth
  class PasswordResetInitiateHandler < RequestHandler
    @schema : PasswordResetInitiateSchema?

    http_method_names :post

    def post
      if schema.valid?
        if user = User.get_by_natural_key(schema.email!)
          PasswordResetEmail.new(user, request).deliver
        end

        # so that attacker doesn't know if email exists or not
        render_no_content
      else
        render_invalid_payload
      end
    rescue e
      handle_error(e)
    end

    private def schema
      @schema ||= PasswordResetInitiateSchema.new(request.data)
    end
  end
end
