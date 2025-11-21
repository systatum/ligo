class UserDetector < Marten::Middleware
  def call(request : Marten::HTTP::Request, get_response : Proc(Marten::HTTP::Response)) : Marten::HTTP::Response
    user = detect_user(request)
    request.current_user = user if user
    get_response.call
  end

  protected def detect_user(request : Marten::HTTP::Request) : Auth::User | Nil
    return nil unless request.headers.has_key?("Authorization")

    auth_header = request.headers["Authorization"]
    jwt_token = auth_header.split.last?
    return nil if jwt_token.nil? || jwt_token.empty?

    begin
      Auth::User.find_by_jwt_token(jwt_token)
    rescue ex
      ip = IPDetector.client_ip(request)
      Log.info { "#{Time.utc.to_rfc3339} - IP: #{ip} - Error: #{ex.class}:#{ex.message} - JWT Token:#{jwt_token}" }
      nil
    end
  end
end
