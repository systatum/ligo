module CurrentUserDetector
  protected def current_user : Auth::User | Nil
    # early return if no authorization header
    return nil unless request.headers.has_key?("Authorization")

    auth_header = request.headers["Authorization"]
    jwt_token = auth_header.split.last.not_nil!

    Auth::User.find_by_jwt_token(jwt_token)
  end

  protected def current_user! : Auth::User
    current_user.not_nil!
  end

  protected def current_organization! : Auth::Organization
    current_user!.organization.not_nil!
  end
end
