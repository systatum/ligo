class OrganizationCreateHandler < RequestHandler
  @schema : Auth::OrganizationSchema?

  http_method_names :post

  def post
    if schema.valid?
      organization = Auth::Organization.new(schema.validated_data)
      organization.save!
      json OrganizationSerializer.serialize(organization), status: 200
    else
      render_invalid_payload
    end
  rescue e
    handle_error(e)
  end

  private def schema
    @schema ||= Auth::OrganizationSchema.new(request.data)
  end
end
