module Workaty
  class TeamDivisionSerializer < ModelSerializer
    protected def fields
      record = @record.as(TeamDivision)

      {
        id:         record.hashed_id,
        name:       record.name,
        leader_ids: record.leaders.map(&.slug),
      }
    end
  end
end
