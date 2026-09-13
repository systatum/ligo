# Automatically respond to all OPTIONS requests with a 200 OK response.
# This is useful for CORS preflight requests, which are sent by browsers
# to check if the server allows cross-origin requests.
class OptionsRequestResponder < Marten::Middleware
  def call(request : Marten::HTTP::Request, get_response : Proc(Marten::HTTP::Response)) : Marten::HTTP::Response
    return get_response.call unless request.method == "OPTIONS"

    return Marten::HTTP::Response.new(
      status: 200,
    )
  end
end
