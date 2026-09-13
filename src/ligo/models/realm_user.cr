module Ligo
  # A RealmUser is a federated identity link: it binds a User to a specific
  # Realm, equivalent to an OAuth `sub` (subject) claim, scoped per client.
  class RealmUser < Marten::Model
    include FieldEnumCoercer

    field :id, :big_int, primary_key: true, auto: true
    field :user, :many_to_one, to: Ligo::User, related: :realm_users
    # OAuth provider type. Stored as raw int, coerced via ProviderType through
    # FieldEnumCoercer.
    field :provider, :int, null: false, blank: false, index: true
    # The user's unique identifier at the OAuth provider (e.g. Facebook user ID).
    # Combined with provider and realm to form a unique constraint.
    field :provider_user_id, :string, max_size: 255, null: false, blank: false, index: true
    # The Realm (app) this user registered through.
    # Each realm gets its own RealmUser record, enabling per-app identity.
    field :realm, :many_to_one, to: Ligo::Realm, related: :realm_users
    # Timestamp of when the target app's backend acknowledged the registration
    # webhook (via 200/204 response). For ack_semantic NONE, this is set at
    # creation time. For MUTUAL, it is set only after successful webhook delivery.
    # For OPTIONAL, it remains null.
    field :acked_at, :date_time, null: true, blank: true
    field :registration_webhook_content_id, :string, max_size: 255, null: true, blank: true
    field :created_at, :date_time, null: false, auto_now_add: true
    field :updated_at, :date_time, null: false, auto_now: true

    field_enum_coercer :provider, ProviderType

    def self.filter(*, provider : ProviderType, provider_user_id : String, realm : Ligo::Realm? = nil)
      if realm
        super(provider: provider.value.to_i64, provider_user_id: provider_user_id, realm: realm)
      else
        super(provider: provider.value.to_i64, provider_user_id: provider_user_id)
      end
    end

    db_unique_constraint :idx_provider_provider_user_id_unique,
      field_names: [:provider, :provider_user_id, :realm]
  end
end
