class UserDetector < Marten::Middleware
  def call(request : Marten::HTTP::Request, get_response : Proc(Marten::HTTP::Response)) : Marten::HTTP::Response
    user = detect_user(request)
    request.current_user = user if user
    Current.set_performer_id(user.try(&.id))
    Current.set_request_context(IPDetector.client_ip(request), request.path)

    begin
      get_response.call
    ensure
      Current.clear
    end
  end

  protected def detect_user(request : Marten::HTTP::Request) : Ligo::User | Nil
    return nil unless request.headers.has_key?("Authorization")

    auth_header = request.headers["Authorization"]
    jwt_token = auth_header.split.last?
    return nil if jwt_token.nil? || jwt_token.empty?

    begin
      Ligo::User.find_by_jwt_token(jwt_token)
    rescue ex
      Logger.info("Failed to detect user - JWT Token: #{jwt_token}")
      nil
    end
  end
end
