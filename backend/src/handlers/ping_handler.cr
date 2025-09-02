class PingHandler < Marten::Handler
  def get
    respond("Pong!", content_type: "text/plain", status: 200)
  end
end
