def create_user(email : String? = nil, password : String = "Password01")
  n = Auth::User.last.nil? ? 1 : (Auth::User.last!.id! + 1)
  unless email
    email = "user#{n}@example.com"
  end

  user = Auth::User.new(email: email)
  user.first_name = "Adam"
  user.set_password(password)
  user.save!

  user
end
