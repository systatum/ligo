class OrganizationDeleteHandler < RequestHandler
  http_method_names :delete

  @organization : Auth::Organization?
  @schema : Auth::OrganizationSchema?

  def delete
    organization.soft_delete!
    json OrganizationSerializer.serialize(organization), status: 200
  rescue e
    handle_error(e)
  end

  private def organization
    @organization ||= Auth::Organization.get_by_hashed_id!(params["hashed_id"].to_s)
  end
end
