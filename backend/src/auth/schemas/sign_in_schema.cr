module Auth
  class SignInSchema < Marten::Schema
    field :email, :email
    field :password, :string, max_size: 128, strip: false
  end
end
