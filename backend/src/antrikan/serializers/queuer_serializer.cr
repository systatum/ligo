module Antrikan
  class QueuerSerializer < ModelSerializer
    protected def fields
      record = @record.as(Queuer)

      {
        id:           record.hashed_id,
        space_id:     record.space!.hashed_id,
        user_id:      record.user.try(&.hashed_id),
        name:         record.name,
        home_address: record.home_address,
        mobile_phone: record.mobile_phone,
        note:         record.note,
      }
    end
  end
end
