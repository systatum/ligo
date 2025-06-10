module Workaty
  class EmployeeSchema < BaseSchema
    field :first_name, :string, max_size: 128, required: true, strip: true
    field :last_name, :string, max_size: 128, required: false, strip: true
    field :email, :string, max_size: 128, required: false, strip: true
    field :phone, :int, required: false
    field :note, :string, required: false, strip: true

    validate :validate_email_uniqueness

    private def validate_email_uniqueness
      if Workaty::Employee.filter(
           email__iexact: email,
           deleted_at: nil,
           organization_id: current_user!.organization_id
         ).exists?
        errors.add(:email, I18n.t("marten.schema.field.email.errors.taken"))
      end
    end
  end
end
