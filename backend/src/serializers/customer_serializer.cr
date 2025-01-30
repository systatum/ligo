class CustomerSerializer < ModelSerializer
  protected def fields
    record = @record.as(Customer)

    {
      id:          record.id,
      slug:        record.slug,
      first_name:  record.first_name,
      middle_name: record.middle_name,
      last_name:   record.last_name,
      gender:      record.gender,
      birthday:    record.birthday,
      note:        record.note,
    }
  end
end
