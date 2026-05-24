module Auth
  class Provider < Marten::Model
    include FieldEnumCoercer

    field :id, :big_int, primary_key: true, auto: true
    field :user, :many_to_one, to: Auth::User, related: :auth_providers
    field :provider, :int, null: false, blank: false, index: true
    field :provider_user_id, :string, max_size: 255, null: false, blank: false, index: true
    field :created_at, :date_time, null: false, auto_now_add: true
    field :updated_at, :date_time, null: false, auto_now: true

    field_enum_coercer :provider, ProviderType

    def self.filter(*, provider : ProviderType, provider_user_id : String)
      super(provider: provider.value.to_i64, provider_user_id: provider_user_id)
    end

    db_unique_constraint :idx_provider_provider_user_id_unique, field_names: [:provider, :provider_user_id]
  end
end
