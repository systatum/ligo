class HomeHandler < RequestHandler
  http_method_names :get

  def get
    json "{}", status: 200
  end
end
