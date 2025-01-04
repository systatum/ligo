require "marten_auth/spec"

require "../../spec_helper"

def create_user(email : String, password : String)
  user = Auth::User.new(email: email)
  user.first_name = "Adam"
  user.set_password(password)
  user.save!

  user
end
