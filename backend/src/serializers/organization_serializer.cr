class OrganizationSerializer < ModelSerializer
  protected def fields
    record = @record.as(Organization)

    {
      id: record.id,
      name: record.name,
    }
  end
end
