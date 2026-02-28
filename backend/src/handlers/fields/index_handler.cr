class FieldIndexHandler < RequestHandler
  protect_from_forgery false
  http_method_names :get

  def get : Marten::HTTP::Response
    resource_type_name = params["resource_type"].to_s
    resource_type = FieldResourceType.parse(resource_type_name)

    fields = FieldDefinition.filter(resource_type: resource_type).map do |f|
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
