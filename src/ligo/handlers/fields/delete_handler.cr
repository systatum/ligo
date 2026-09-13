class FieldDeleteHandler < RequestHandler
  protect_from_forgery false
  http_method_names :post

  def post : Marten::HTTP::Response
    hashed = params["field_hashed_id"].to_s
    field = Ligo::FieldDefinition.get_by_hashed_id!(hashed)

    field.soft_delete!
    json FieldDefinitionSerializer.dump(field), status: 200
  end
end
