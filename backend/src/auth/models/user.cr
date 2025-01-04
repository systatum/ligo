module Auth
  class User < MartenAuth::User
    field :first_name, :string, max_size: 255, null: false, blank: false
    field :last_name, :string, max_size: 255, null: false, blank: true
    field :role, :enum, values: Role, null: false, blank: false, index: true
  end
end
