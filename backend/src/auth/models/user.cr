module Auth
  class User < MartenAuth::User
    include IdConcealer
    include ChangeTracker
    include SoftDeleter
    include JwtPayloader
    include IamIdentifiable

    ALLOWED_LOCALES = ["en-US", "id-ID", "ja-JP"]

    field :organization, :many_to_one, to: Auth::Organization, related: :users, null: true, blank: true
    field :first_name, :string, max_size: 255, null: false, blank: false
    field :last_name, :string, max_size: 255, null: true, blank: true
    field :locale, :string, max_size: 7, null: false, blank: false, default: "en-US"
    field :timezone_offset_seconds, :int, null: true, blank: true
    field :role, :int, null: false, blank: false, index: true, default: Auth::Role::GUEST
    field :password_updated_at, :date_time, null: false, blank: false
    field :reset_password_token, :string, max_size: 255, null: true, blank: true
    field :reset_password_token_created_at, :date_time, null: true, blank: true
    field :uploaded_profile_picture_file_id, :uuid, null: true, blank: true
    field :iam_identifier_primary, :string, max_size: 255, null: true, blank: true, index: true

    def generate_password_reset_token
      # Base64 encodes every 3 bytes into 4 characters, so (191 * 4 / 3).ceil = 255
      token = Random::Secure.urlsafe_base64(191)
      self.reset_password_token = token
      self.reset_password_token_created_at = Time.utc
      token
    end

    def valid_password_reset_token?(token : String) : Bool
      return false if token.blank?
      return false unless (stored = self.reset_password_token)
      return false unless (created_at = self.reset_password_token_created_at)

      expiry_duration = AppSettings.instance.ligo_app_password_reset_token_expiry_minutes.minutes
      token_matches = Crypto::Subtle.constant_time_compare(token, stored)
      token_fresh = (Time.utc - created_at) <= expiry_duration

      token_matches && token_fresh
    end

    def set_password(password)
      super(password)
      self.password_updated_at = Time.utc
    end

    def admin?
      Role.admin?(self)
    end
  end
end
