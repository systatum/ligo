module Auth
  class PasswordResetInitiateSchema < BaseSchema
    field :email, :email
  end
end
