class OrganizationSerializer < ModelSerializer
  protected def fields
    record = @record.as(Auth::Organization)

    {
      id:   record.hashed_id,
      name: record.name,
    }
  end
end
