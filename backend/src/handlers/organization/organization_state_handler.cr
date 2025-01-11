class OrganizationStateHandler < RequestHandler
  http_method_names :patch, :post, :delete

  @organization : Organization?
  @schema : OrganizationSchema?

  def post
    patch
  end

  def patch
    if schema.valid?
      organization.update!(schema.validated_data)
      json OrganizationSerializer.serialize(organization), status: 200
    else
      render_invalid_payload
    end
  rescue e
    handle_error(e)
  end

  def delete
    organization.soft_delete!
    json OrganizationSerializer.serialize(organization), status: 200
  rescue e
    handle_error(e)
  end

  private def organization
    @organization ||= Organization.get!(id: params["pk"])
  end

  private def schema
    @schema ||= OrganizationSchema.new(request.data)
  end
end
