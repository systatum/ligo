module Ligo
  class PasswordResetInitiateHandler < RequestHandler
    protect_from_forgery false
    http_method_names :post

    @schema : PasswordResetInitiateSchema?

    def post
      if schema.valid?
        User::PasswordResetInitiateJob.async.perform(schema.email!)

        # so that attacker doesn't know if email exists or not
        render_no_content
      else
        render_invalid_payload(schema)
      end
    end

    private def schema
      @schema ||= PasswordResetInitiateSchema.new(request.data)
    end
  end
end
