module ExceptionsHandler
  macro included
    rescue_from Marten::HTTP::Errors::PermissionDenied do
      handle_permission_denied(error)
    end

    rescue_from Marten::HTTP::Errors::NotFound,
      Marten::DB::Errors::RecordNotFound do
      handle_not_found(error)
    end

    rescue_from JSON::ParseException do
      handle_json_parse_error(error)
    end

    rescue_from Prorate::Throttled do
      handle_throttled(error)
    end

    rescue_from Exception do
      handle_generic_error(error)
    end
  end

  private def handle_permission_denied(e)
    debug_exception(e)
    render_error 403, ["Not authorized"]
  end

  private def handle_not_found(e)
    debug_exception(e)
    render_error 404, ["Not found"]
  end

  private def handle_json_parse_error(e)
    debug_exception(e)
    render_error 400, ["Invalid JSON format"]
  end

  private def handle_throttled(e : Prorate::Throttled)
    debug_exception(e)
    response = render_error 429, [e.message]
    response.headers["Retry-After"] = e.retry_in_seconds.to_s
    response
  end

  private def handle_generic_error(e)
    debug_exception(e)
    render_error 400, [e.message || "Unknown error"]
  end

  private def debug_exception(e)
    Logger.error("#{e.class}: #{e.message}", err: e)
  end
end
