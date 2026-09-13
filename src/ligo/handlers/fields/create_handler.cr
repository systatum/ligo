class FieldCreateHandler < RequestHandler
  protect_from_forgery false
  http_method_names :post

  def post : Marten::HTTP::Response
    if schema.valid?
      field = Ligo::FieldDefinition.new
      field.resource_type = schema.resource_type
      field.name = schema.name
      field.data_type = schema.data_type
      field.localized_name = schema.localized_name
      field.nullable = schema.nullable if request.data.has_key?("localized_name")
      field.uniqueness = schema.uniqueness
      field.metadata = schema.metadata if request.data.has_key?("metadata")

      field.save!
      json FieldDefinitionSerializer.dump(field), status: 200
    else
      render_invalid_payload(schema)
    end
  end

  private def schema
    @schema ||= FieldDefinitionSchema.new(request.data)
  end
end
