class Workaty::DegreeSerializer < ModelSerializer
  protected def fields
    record = @record.as(Degree)

    {
      id:          record.hashed_id,
      institution: record.institution,
      level:       record.level,
      field:       {
        major: record.major_field,
      },
      obtained_at: record.obtained_at,
    }
  end
end
