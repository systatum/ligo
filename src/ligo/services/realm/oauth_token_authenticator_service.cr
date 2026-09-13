module Ligo
  class OAuthTokenAuthenticatorService < BaseService(Ligo::User)
    def initialize(@realm : Realm, @multi_auth : MultiAuth::Engine, @code : String)
    end

    def run : ServiceResult(Ligo::User)
      multi_auth_user = @multi_auth.user({"code" => @code})

      provider_type = ProviderType.parse(multi_auth_user.provider)
      raw_provider = provider_type.value.to_i64
      resolved_email = multi_auth_user.email.presence || oauth_placeholder_email(multi_auth_user)

      identity_link = Ligo::RealmUser.filter(
        provider: provider_type,
        provider_user_id: multi_auth_user.uid,
        realm: @realm
      ).first?

      return success(identity_link.user!) if identity_link

      user = Ligo::User.filter(email__iexact: resolved_email).first? || begin
        Ligo::User.new(
          email: resolved_email,
          first_name: multi_auth_user.first_name || multi_auth_user.name,
          last_name: multi_auth_user.last_name,
          password_updated_at: Time.utc
        ).tap(&.set_unusable_password)
      end

      user.generate_iam_identifier!

      user.save! unless user.persisted?

      has_user = Ligo::RealmUser.filter(
        provider: provider_type,
        provider_user_id: multi_auth_user.uid,
        realm: @realm
      ).exists?

      unless has_user
        realm_user = Ligo::RealmUser.create!(
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

            WebhookDeliveryWorker.async do |job|
              job.retry = (@realm.max_ack_retry_attempts || Realm::DEFAULT_MAX_ACK_RETRY_ATTEMPTS).to_i
            end.perform(
              content_id,
              ack_uri,
              @realm.webhook_secret.not_nil!,
              body,
              @realm.ack_semantic
            )
          end
        end
      end

      success(user)
    rescue ex
      failure(:code, ex.message || "OAuth sign-in failed")
    end

    private def oauth_placeholder_email(multi_auth_user : MultiAuth::User) : String
      # find_by_jwt_token falls back to email lookup, so a stable placeholder
      # is needed even when the OAuth provider withholds the real address.
      safe_uid = multi_auth_user.uid.gsub(/[^A-Za-z0-9._%+-]/, "-")
      "#{multi_auth_user.provider.downcase}-#{safe_uid}@oauth.invalid"
    end
  end
end
