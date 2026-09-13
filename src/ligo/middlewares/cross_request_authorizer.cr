class CrossRequestAuthorizer < Marten::Middleware
  def call(request : Marten::HTTP::Request, get_response : Proc(Marten::HTTP::Response)) : Marten::HTTP::Response
    response = get_response.call
    headers = response.headers

    headers["Access-Control-Allow-Origin"] = AppSettings.instance.ligo_app_cors_whitelist
    headers["Access-Control-Allow-Methods"] = "GET, DELETE, PATCH, PUT, POST, OPTIONS"
    headers["Access-Control-Allow-Headers"] = AppSettings.instance.ligo_app_cors_ok_headers

    response
  end
end
