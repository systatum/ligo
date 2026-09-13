module Ligo
  class PasswordResetConfirmSchema < BaseSchema
    field :hashed_id, :string, required: true
    field :token, :string, strip: false, required: true
    field :password1, :string, max_size: 128, strip: false, required: true
    field :password2, :string, max_size: 128, strip: false, required: true

    validate :validate_passwords_match
    validate :validate_token

    @user : Ligo::User?

    def user : Ligo::User?
      @user ||= User.get_by_hashed_id(hashed_id!) if hashed_id?
    end

    private def validate_passwords_match
      return unless password1? && password2?
      return if password1 == password2

      errors.add(:password2, "Does not match to each other")
    end

    private def validate_token
      return unless hashed_id? && token?

      unless (u = user)
        errors.add(:hashed_id, "User not found")
        return
      end

      unless u.valid_password_reset_token?(token!)
        errors.add(:token, "Invalid or expired token")
      end
    end
  end
end
