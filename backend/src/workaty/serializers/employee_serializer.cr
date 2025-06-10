module Workaty
  class EmployeeSerializer < ModelSerializer
    protected def fields
      record = @record.as(Employee)

      {
        id:         record.slug,
        first_name: record.first_name,
        last_name:  record.last_name,
        email:      record.email,
        phone:      record.phone,
        note:       record.note,
      }
    end
  end
end
