module Auth
  class OAuthTokenAuthenticatorService < BaseService(Auth::User)
    def initialize(@realm : Realm, @multi_auth : MultiAuth::Engine, @code : String)
    end

    def run : ServiceResult(Auth::User)
      multi_auth_user = @multi_auth.user({"code" => @code})

      provider_type = Auth::ProviderType.parse(multi_auth_user.provider)
      raw_provider = provider_type.value.to_i64
      resolved_email = multi_auth_user.email.presence || oauth_placeholder_email(multi_auth_user)

      identity_link = Auth::RealmUser.filter(
        provider: provider_type,
        provider_user_id: multi_auth_user.uid,
        realm: @realm
      ).first?

      return success(identity_link.user!) if identity_link

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

      has_user = Auth::RealmUser.filter(
        provider: provider_type,
        provider_user_id: multi_auth_user.uid,
        realm: @realm
      ).exists?

      unless has_user
        realm_user = Auth::RealmUser.create!(
          user: user,
          provider: raw_provider,
          provider_user_id: multi_auth_user.uid,
          realm: @realm
        )

        case @realm.ack_semantic
        when AcknowledgeSemantic::NONE
          realm_user.update!(acked_at: Time.utc)
        else
          if (ack_uri = @realm.registration_ack_uri.presence)
            content_id = UUID.random.to_s
            realm_user.update!(registration_webhook_content_id: content_id)

            body = {
              event:         "registration",
              user_id:       realm_user.user!.hashed_id,
              email:         realm_user.user!.email,
              realm_user_id: realm_user.id!,
            }.to_json

            webhook_job = WebhookDeliveryWorker.async do |job|
              job.retry = (@realm.max_ack_retry_attempts || 50).to_i
            end

            webhook_job.perform(
              content_id,
              ack_uri,
              @realm.webhook_secret.not_nil!,
              body,
              @realm.ack_semantic
            )
          end
          # registration_ack_uri is optional, so when it's empty,
          # we don't have to do much else here
        end
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
