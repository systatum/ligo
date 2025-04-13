module Workaty
  class CandidateSerializer < ModelSerializer
    protected def fields
      record = @record.as(Candidate)

      {
        id:         record.slug,
        first_name: record.first_name,
        last_name:  record.last_name,
        fitness:    record.fitness,
        email:      record.email,
        phone:      record.phone,
        degrees:    degrees,
      }
    end

    private def degrees
      @record.as(Candidate).degrees.map do |degree|
        DegreeSerializer.soft_serialize(degree)
      end
    end
  end
end
