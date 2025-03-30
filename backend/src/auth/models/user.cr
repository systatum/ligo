module Auth
  class User < MartenAuth::User
    include IdConcealer
    include ChangeTracker
    include SoftDeleter
    include JwtPayloader

    field :first_name, :string, max_size: 255, null: false, blank: false
    field :last_name, :string, max_size: 255, null: true, blank: true
    field :role, :int, null: false, blank: false, index: true, default: Role::GUEST
    field :password_updated_at, :date_time, null: false, blank: false

    def set_password(password)
      super(password)
      self.password_updated_at = Time.utc
    end
  end
end
