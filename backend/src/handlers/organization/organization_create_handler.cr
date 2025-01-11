class OrganizationCreateHandler < RequestHandler
  @schema : OrganizationSchema?

  http_method_names :post

  def post
    if schema.valid?
      organization = Organization.new(schema.validated_data)
      organization.save!
      json OrganizationSerializer.serialize(organization), status: 200
    else
      render_invalid_payload
    end
  end

  private def schema
    @schema ||= OrganizationSchema.new(request.data)
  end
end
