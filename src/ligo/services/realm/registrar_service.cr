require "openssl"

module Ligo
  alias RawRealmCredentials = NamedTuple(
    api_secret_key: String,
    api_client_key: String,
    webhook_secret: String,
  )

  class Realm::RegistrarService < BaseService(RawRealmCredentials)
    def initialize(@data : Marten::HTTP::Params::Data)
    end

    def run : ServiceResult(RawRealmCredentials)
      return failure(schema.errors) unless schema.valid?

      begin
        credentials = RawRealmCredentials.new(
          api_secret_key: Random::Secure.urlsafe_base64(45),
          api_client_key: Random::Secure.urlsafe_base64(45),
          webhook_secret: Random::Secure.urlsafe_base64(11)
        )

        realm = Ligo::Realm.new
        realm.id = SlugGenerator.generate(12)
        realm.app_name = schema.app_name
        realm.app_id = schema.app_id
        realm.app_secret = schema.app_secret
        realm.hashed_api_secret_key = Digest::SHA256.hexdigest(credentials[:api_secret_key])
        realm.hashed_api_client_key = Digest::SHA256.hexdigest(credentials[:api_client_key])
        realm.webhook_secret = credentials[:webhook_secret]
        realm.ack_semantic = schema.ack_semantic
        realm.default_role = schema.default_role! if schema.default_role?
        realm.registration_redirection_uri = schema.registration_redirection_uri if schema.registration_redirection_uri?
        realm.registration_ack_uri = schema.registration_ack_uri if schema.registration_ack_uri?
        realm.max_ack_retry_attempts = schema.max_ack_retry_attempts if schema.max_ack_retry_attempts?

        realm.save!

        success(credentials)
      rescue ex : Marten::DB::Errors::InvalidRecord
        failure(ex.record.errors)
      end
    end

    private def schema
      @schema ||= Ligo::RealmSchema.new(@data)
    end
  end
end
