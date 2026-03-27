module Auth
  class PasswordResetInitiateSchema < BaseSchema
    field :email, :email, required: true
  end
end
