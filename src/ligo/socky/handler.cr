class Socky::Handler
  include ::HTTP::Handler

  PATH = "/ws"

  def call(context : ::HTTP::Server::Context)
    return call_next(context) unless context.request.path == PATH &&
                                     context.request.headers["Upgrade"]?.try(&.downcase) == "websocket"

    user = authenticate(context.request)
    return unauthorized(context) unless user

    # here we delegate websocket handshake and its intricacies
    # to a new HTTP::WebSocketHandler instance, so we can just
    # focus on our own JWT authentication
    ::HTTP::WebSocketHandler.new(subprotocols: ["bearer"]) do |socket, _ctx|
      Socky::Connection.new(user, socket).start
    end.call(context)
  end

  # JWT travels as a WebSocket subprotocol ("Sec-WebSocket-Protocol: bearer,
  # <token>") since the browser API won't let us set an Authorization header
  # on the handshake. Same validation as REST auth, just a different transport.
  private def authenticate(request) : Ligo::User?
    begin
      raw = request.headers["Sec-WebSocket-Protocol"]?
      return nil unless raw

      parts = raw.split(",", 2).map(&.strip)
      return nil unless parts.size == 2 && parts[0] == "bearer"

      jwt_token = parts[1]
      Ligo::User.find_by_jwt_token(jwt_token)
    rescue
      nil
    end
  end

  private def unauthorized(context)
    context.response.status_code = 401
    context.response.print("Unauthorized")
  end
end
