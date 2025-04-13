class AppInfoHandler < Marten::Handler
  def get
    response_payload = Jbuilder.new do |json|
      json.name "Ligo"
    end.to_json

    json response_payload, status: 200
  end
end
