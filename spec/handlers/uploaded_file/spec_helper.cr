require "../../spec_helper"

def auth_headers_for(user)
  {authorization: "Bearer #{user.jwt_token}"}
end
