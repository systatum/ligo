require "../spec_helper"

describe Socky::Handler do
  describe "#call" do
    it "passes through non-WS requests" do
      handler = Socky::Handler.new
      fallthrough = ->(ctx : HTTP::Server::Context) {
        ctx.response.status_code = 404
        ctx.response.print("Not Found")
      }
      handler.next = fallthrough

      request = HTTP::Request.new("GET", "/api/something")
      io = IO::Memory.new
      response = HTTP::Server::Response.new(io)
      context = HTTP::Server::Context.new(request, response)

      handler.call(context)

      response.status_code.should eq 404
    end

    it "passes through non-upgrade requests to /ws" do
      handler = Socky::Handler.new
      fallthrough = ->(ctx : HTTP::Server::Context) {
        ctx.response.status_code = 404
        ctx.response.print("Not Found")
      }
      handler.next = fallthrough

      request = HTTP::Request.new("GET", "/ws")
      io = IO::Memory.new
      response = HTTP::Server::Response.new(io)
      context = HTTP::Server::Context.new(request, response)

      handler.call(context)

      response.status_code.should eq 404
    end

    it "returns 401 when Sec-WebSocket-Protocol is missing" do
      handler = Socky::Handler.new

      headers = HTTP::Headers.new
      headers["Upgrade"] = "websocket"
      request = HTTP::Request.new("GET", "/ws", headers: headers)
      io = IO::Memory.new
      response = HTTP::Server::Response.new(io)
      context = HTTP::Server::Context.new(request, response)

      handler.call(context)

      response.status_code.should eq 401
    end

    it "returns 401 when Sec-WebSocket-Protocol has no bearer marker" do
      handler = Socky::Handler.new

      headers = HTTP::Headers.new
      headers["Upgrade"] = "websocket"
      headers["Sec-WebSocket-Protocol"] = "not_bearer,token"
      request = HTTP::Request.new("GET", "/ws", headers: headers)
      io = IO::Memory.new
      response = HTTP::Server::Response.new(io)
      context = HTTP::Server::Context.new(request, response)

      handler.call(context)

      response.status_code.should eq 401
    end

    it "returns 401 when JWT token is invalid" do
      handler = Socky::Handler.new

      headers = HTTP::Headers.new
      headers["Upgrade"] = "websocket"
      headers["Sec-WebSocket-Protocol"] = "bearer, invalid_token"
      request = HTTP::Request.new("GET", "/ws", headers: headers)
      io = IO::Memory.new
      response = HTTP::Server::Response.new(io)
      context = HTTP::Server::Context.new(request, response)

      handler.call(context)

      response.status_code.should eq 401
    end
  end
end
