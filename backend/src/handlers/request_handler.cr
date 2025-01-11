class RequestHandler < Marten::Handler
  protected def handle_error(e)
    case e
    when Marten::HTTP::Errors::NotFound | Marten::DB::Errors::RecordNotFound
      render_error 404, ["Not found"]
    else
      render_error 400, [e.message]
    end
  end

  protected def render_error(status_code, messages)
    response_payload = Jbuilder.new do |json|
      json.error do |json|
        json.messages messages
      end
    end.to_json

    json response_payload, status: status_code
  end

  protected def render_invalid_payload
    render_error 400, ["Invalid payload"]
  end
end
