class Workaty::FieldsShowHandler < RequestHandler
  protect_from_forgery false
  http_method_names :get

  def get : Marten::HTTP::Response
    resource_type_value = params["resource_type"].to_s.to_i
    resource_type = FieldResourceType.from_value?(resource_type_value)

    unless resource_type
      return render_error 404, ["Resource type not found"]
    end

    fields = FieldDefinitionSerializer.dump(resource_type)

    resp = Marten::HTTP::Response.new(
      content: {"fields" => fields}.to_json,
      content_type: "application/json",
      status: 200
    )
    resp.headers["Cache-Control"] = "public, max-age=3600"
    resp
  end
end
