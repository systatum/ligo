module Auth
  class User < MartenAuth::User
    include IdConcealer
    include ChangeTracker
    include SoftDeleter
    include JwtPayloader

    ALLOWED_LOCALES = ["en-US", "id-ID", "ja-JP"]

    field :organization, :many_to_one, to: Auth::Organization, related: :users
    field :first_name, :string, max_size: 255, null: false, blank: false
    field :last_name, :string, max_size: 255, null: true, blank: true
    field :locale, :string, max_size: 7, null: false, blank: false, default: "en-US"
    field :timezone_offset_seconds, :int, null: true, blank: true
    field :role, :int, null: false, blank: false, index: true, default: Auth::Role::GUEST
    field :password_updated_at, :date_time, null: false, blank: false
    field :uploaded_profile_picture_file_id, :uuid, null: true, blank: true

    def set_password(password)
      super(password)
      self.password_updated_at = Time.utc
    end

    def admin?
      Role.admin?(self)
    end
  end
end
