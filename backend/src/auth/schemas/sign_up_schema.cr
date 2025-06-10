module Auth
  class SignUpSchema < BaseSchema
    field :email, :email, required: true
    field :password, :string, max_size: 128, strip: false, required: true
    field :first_name, :string, max_size: 255, strip: true, required: true
    field :last_name, :string, max_size: 255, strip: true, required: false

    field :organization_id, :string, strip: true, required: false
    field :organization_name, :string, max_size: 255, strip: true, required: false

    validate :validate_email
    validate :validate_organization

    @organization : Auth::Organization?

    def organization : Auth::Organization?
      @organization ||= begin
        if organization_id?
          Organization.get_by_hashed_id(organization_id!)
        elsif organization_name?
          Organization.create!(name: organization_name!)
        else
          raise "Organization must be set, either by name or by ID"
        end
      end
    end

    private def validate_email
      return unless email?

      if User.filter(email__iexact: email).exists?
        errors.add(:email, I18n.t("marten.schema.field.email.errors.taken"))
      end
    end

    private def validate_organization
      if !organization_id? && !organization_name?
        errors.add(:organization, "Organization must be set, either by name or by ID")
      end
    end
  end
end
