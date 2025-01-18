module CurrentUserDetector
  protected def current_user : Auth::User | Nil
    auth_header = request.headers["Authorization"]
    jwt_token = auth_header.split.last.not_nil!

    Auth::User.find_by_jwt_token(jwt_token)
  end
end
