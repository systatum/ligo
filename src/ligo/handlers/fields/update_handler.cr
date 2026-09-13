class FieldUpdateHandler < RequestHandler
  protect_from_forgery false
  http_method_names :post

  def post : Marten::HTTP::Response
    hashed = params["field_hashed_id"].to_s
    field = Ligo::FieldDefinition.get_by_hashed_id!(hashed)

    if schema.valid?
      field.resource_type = schema.resource_type
      field.name = schema.name
      field.data_type = schema.data_type
      field.localized_name = schema.localized_name if request.data.has_key?("localized_name")
      field.nullable = schema.nullable if request.data.has_key?("nullable")
      field.uniqueness = schema.uniqueness if request.data.has_key?("uniqueness")
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
