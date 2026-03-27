module Antrikan
  class SpaceSerializer < ModelSerializer
    protected def fields
      record = @record.as(Space)

      {
        id:                   record.hashed_id,
        code:                 record.code,
        name:                 record.name,
        need_manual_approval: record.need_manual_approval,
        has_operating_hours:  record.has_operating_hours,
        logo_file_id:         record.logo_file_id.to_s,
      }
    end
  end
end
