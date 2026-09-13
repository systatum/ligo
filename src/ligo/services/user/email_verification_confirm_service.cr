module Ligo
  class User::EmailVerificationConfirmService < BaseService(Ligo::User)
    def initialize(
      @code : String,
      @user_hashed : String? = nil,
    )
    end

    def run : ServiceResult(Ligo::User)
      user = resolve_user
      return failure("Invalid verification code") if user.nil?

      if user.is_email_address_verified?
        return success(user)
      end

      unless user.valid_email_verification_token?(@code)
        return failure("Invalid or expired verification code")
      end

      user.is_email_address_verified = true
      user.email_verification_token = nil
      user.email_verification_token_created_at = nil
      user.email_verification_token_expired_at = nil
      user.save!

      success(user)
    end

    private def resolve_user : Ligo::User?
      if @user_hashed
        User.get_by_hashed_id(@user_hashed.not_nil!)
      else
        User.filter(email_verification_token: @code).first?
      end
    end
  end
end
