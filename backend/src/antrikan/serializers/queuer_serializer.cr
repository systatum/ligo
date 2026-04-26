module Antrikan
  class QueuerSerializer < ModelSerializer
    protected def fields
      record = @record.as(Queuer)

      {
        id:       record.hashed_id,
        space_id: record.space!.hashed_id,
        user_id:  record.user.try(&.hashed_id),
        name:     record.name,
      }
    end
  end
end
