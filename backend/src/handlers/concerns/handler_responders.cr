module HandlerResponders
  def render_no_content
    json "{}", status: 200
  end

  protected def handle_error(e)
    if ENV["MARTEN_ENV"] == "test"
      puts e.message
      e.backtrace.each do |line|
        # skip noise lines
        next if line.includes?("lib/marten") || line.includes?("marten/src/") ||
                line.includes?("crystal/src") || line.includes?("crystal/core/") ||
                line.includes?("??")

        puts "#{line}\n"
      end

      puts "\n"
    end

    # todo: send the error to sentry

    case e
    when Marten::HTTP::Errors::PermissionDenied
      render_error 403, ["Not authorized"]
    when Marten::HTTP::Errors::NotFound | Marten::DB::Errors::RecordNotFound
      render_error 404, ["Not found"]
    else
      err_msg = e.message || "Unknown error"
      render_error 400, [err_msg]
    end
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
