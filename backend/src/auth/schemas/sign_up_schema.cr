module Auth
  class SignUpSchema < Marten::Schema
    field :email, :email, required: true
    field :password, :string, max_size: 128, strip: false, required: true
    field :first_name, :string, max_size: 255, strip: true, required: true
    field :last_name, :string, max_size: 255, strip: true, required: false

    validate :validate_email

    private def validate_email
      return unless email?

      if User.filter(email__iexact: email).exists?
        errors.add(:email, "This address is taken")
      end
    end
  end
end
