module Auth
  class OAuthTokenAuthenticatorService < BaseService(Auth::User)
    def initialize(@multi_auth : MultiAuth::Engine, @code : String)
    end

    def run : ServiceResult(Auth::User)
      multi_auth_user = @multi_auth.user({"code" => @code})

      provider_type = Auth::ProviderType.parse(multi_auth_user.provider)
      resolved_email = multi_auth_user.email.presence || oauth_placeholder_email(multi_auth_user)

      provider_link = Auth::Provider.filter(
        provider: provider_type,
        provider_user_id: multi_auth_user.uid
      ).first?

      return success(provider_link.user!) if provider_link

      user = Auth::User.filter(email__iexact: resolved_email).first? || begin
        Auth::User.new(
          email: resolved_email,
          first_name: multi_auth_user.first_name || multi_auth_user.name,
          last_name: multi_auth_user.last_name,
          password_updated_at: Time.utc
        ).tap(&.set_unusable_password)
      end

      user.generate_iam_identifier!

      user.save! unless user.persisted?

      unless Auth::Provider.filter(provider: provider_type, provider_user_id: multi_auth_user.uid).exists?
        Auth::Provider.create!(
          user: user,
          provider: provider_type.value.to_i64,
          provider_user_id: multi_auth_user.uid
        )
      end

      success(user)
    rescue ex
      failure(:code, ex.message || "OAuth sign-in failed")
    end

    private def oauth_placeholder_email(multi_auth_user : MultiAuth::User) : String
      # this is kinda needed because resolving user via JWT payload requires
      # an email that matches an existing realm-local user as fallback
      safe_uid = multi_auth_user.uid.gsub(/[^A-Za-z0-9._%+-]/, "-")
      "#{multi_auth_user.provider.downcase}-#{safe_uid}@oauth.invalid"
    end
  end
end
