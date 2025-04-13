class HomeHandler < RequestHandler
  protect_from_forgery false
  http_method_names :get

  def get
    json "{}", status: 200
  end
end
