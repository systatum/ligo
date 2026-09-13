class FieldIndexHandler < RequestHandler
  protect_from_forgery false
  http_method_names :get

  def get : Marten::HTTP::Response
    resource_type = params["resource_type"].as(UInt64).to_i64

    fields = Ligo::FieldDefinition.filter(resource_type: resource_type).map do |f|
      FieldDefinitionSerializer.dump(f)
    end

    resp = Marten::HTTP::Response.new(
      content: {"fields" => fields}.to_json,
      content_type: "application/json",
      status: 200
    )
    resp.headers["Cache-Control"] = "public, max-age=3600"
    resp
  end
end
