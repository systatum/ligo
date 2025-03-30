class OrganizationUpdateHandler < RequestHandler
  http_method_names :patch, :post

  @organization : Auth::Organization?
  @schema : Auth::OrganizationSchema?

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

  private def organization
    @organization ||= Auth::Organization.get_by_hashed_id!(params["hashed_id"].to_s)
  end

  private def schema
    @schema ||= Auth::OrganizationSchema.new(request.data)
  end
end
