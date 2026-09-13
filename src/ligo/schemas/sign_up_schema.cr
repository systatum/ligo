module Ligo
  class SignUpSchema < BaseSchema
    field :email, :email, required: true
    field :password, :string, max_size: 128, strip: false, required: true
    field :first_name, :string, max_size: 255, strip: true, required: true
    field :last_name, :string, max_size: 255, strip: true, required: false

    field :organization_id, :string, strip: true, required: false
    field :organization_name, :string, max_size: 255, strip: true, required: false

    field :realm_id, :string, strip: true, required: true
    field :api_client_key, :string, strip: true, required: true

    validate :validate_email
    validate :validate_organization
    validate :validate_realm

    @organization : Ligo::Organization?
    @realm : Ligo::Realm?

    def organization : Ligo::Organization?
      @organization ||= begin
        if organization_id?
          Organization.get_by_hashed_id(organization_id!)
        elsif organization_name?
          Organization.create!(name: organization_name!)
        else
          raise "Organization must be set, either by name or by ID"
        end
      end
    end

    def realm : Ligo::Realm?
      @realm ||= Realm.filter(id: realm_id!).first if realm_id?
    end

    def realm! : Ligo::Realm
      realm.not_nil!
    end

    private def validate_email
      return unless email?

      if User.filter(email__iexact: email).exists?
        errors.add(:email, I18n.t("marten.schema.field.email.errors.taken"))
      end
    end

    private def validate_organization
      if !organization_id? && !organization_name?
        errors.add(:organization, "Organization must be set, either by name or by ID")
      end
    end

    private def validate_realm
      return unless realm_id?

      unless (realm = self.realm)
        errors.add(:realm_id, "Realm not found")
        return
      end

      return unless api_client_key?

      unless Crypto::Subtle.constant_time_compare(Digest::SHA256.hexdigest(api_client_key!), realm.hashed_api_client_key!)
        errors.add(:api_client_key, "Invalid API client key")
      end
    end
  end
end
