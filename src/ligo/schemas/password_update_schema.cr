module Ligo
  class PasswordUpdateSchema < BaseSchema
    property :user

    field :current_password, :string, max_size: 128, strip: false
    field :new_password, :string, max_size: 128, strip: false
    field :new_password_confirm, :string, max_size: 128, strip: false

    @user : User?

    validate :validate_password_matches
    validate :validate_old_password

    private def validate_password_matches
      return if new_password == new_password_confirm

      errors.add(:new_password, "Does not match to each other")
    end

    private def validate_old_password
      return if @user.not_nil!.check_password(current_password!)

      errors.add(:current_password, "Invalid")
    end
  end
end
