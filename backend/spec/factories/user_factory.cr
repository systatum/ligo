require "./organization_factory"

def create_user(
  organization : Auth::Organization = create_organization,
  email : String? = nil,
  password : String = "Password01",
  role : Int = Auth::Role::OWNER,
  iam_identifier_primary : String? = nil,
)
  n = Auth::User.last.nil? ? 1 : (Auth::User.last!.id! + 1)
  unless email
    email = "user#{n}@example.com"
  end

  unless iam_identifier_primary
    iam_identifier_primary = "spec-iam-user-#{n}"
  end

  user = Auth::User.new(
    organization: organization,
    email: email,
    role: role,
    first_name: "Adam",
    iam_identifier_primary: iam_identifier_primary,
  )

  user.set_password(password)
  user.save!

  user
end
