module HandlerResponders
  def render_no_content
    json "{}", status: 200
  end

  protected def render_error(status_code, messages : Array(String))
    response_payload = Jbuilder.new do |json|
      json.error do |json|
        json.messages messages
      end
    end.to_json

    json response_payload, status: status_code
  end

  # Render payload/schema-related error. If the schema is given, we will
  # fetch the error from the schema, otherwise a generic error is given
  protected def render_invalid_payload(schema : Marten::Schema? = nil)
    if schema && schema.errors.any?
      render_error 422, flatten_error_set(schema.errors)
    else
      render_error 422, ["Invalid payload"]
    end
  end

  protected def render_invalid_payload(errors : Marten::Core::Validation::ErrorSet? = nil)
    if errors && errors.any?
      render_error 422, flatten_error_set(errors)
    else
      render_error 422, ["Invalid payload"]
    end
  end

  private def flatten_error_set(errors)
    error_messages = [] of String

    errors.each do |error|
      if error.field
        error_messages << "#{error.field.to_s.capitalize.gsub("_", " ")}: #{error.message}"
      else
        error_messages << error.message
      end
    end

    error_messages
  end
end
