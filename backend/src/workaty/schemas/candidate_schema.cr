module Workaty
  class CandidateSchema < BaseSchema
    field :first_name, :string, max_size: 128, required: true, strip: true
    field :last_name, :string, max_size: 128, required: false, strip: true
    field :fitness, :enum, values: Workaty::Candidate::Fitness, required: false
    field :email, :string, max_size: 128, required: false, strip: true
    field :phone, :int, required: false
    field :note, :string, required: false, strip: true

    validate :validate_email_uniqueness
    before_validation :coerce_default_fitness

    private def validate_email_uniqueness
      return if email.nil? || email.try(&.empty?)

      users_with_similar_email = Workaty::Candidate.filter(
        email__iexact: email,
        deleted_at: nil,
        organization_id: current_user!.organization_id
      )

      if users_with_similar_email.exists?
        errors.add(:email, I18n.t("marten.schema.field.email.errors.taken"))
      end
    end

    private def coerce_default_fitness
      default_fitness = Workaty::Candidate::Fitness::UNKNOWN.to_s
      @validated_data["fitness"] = self.fitness.to_s.presence || default_fitness
    end
  end
end
