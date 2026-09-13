module Ligo
  class PasswordResetInitiateSchema < BaseSchema
    field :email, :email, required: true
  end
end
