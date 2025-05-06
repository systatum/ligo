module Workaty
  class TeamDivisionSchema < Marten::Schema
    property :user

    field :name, :string, max_size: 255, required: true, strip: true

    @user : Auth::User?

    validate :validate_name_uniqueness

    private def validate_name_uniqueness
      raise "User not set" unless user

      if Workaty::TeamDivision.filter(
           name__iexact: name,
           deleted_at: nil,
           organization_id: user.not_nil!.organization_id
         ).exists?
        errors.add(:name, "must be unique")
      end
    end
  end
end
