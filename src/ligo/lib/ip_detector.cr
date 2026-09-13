module IPDetector
  extend self

  def client_ip(request : Marten::HTTP::Request) : String
    if value = request.headers["X-Forwarded-For"]?
      return parse_ip(value) unless value.empty?
    end

    if value = request.headers["x-forwarded-for"]?
      return parse_ip(value) unless value.empty?
    end

    if value = request.headers["HTTP_X_FORWARDED_FOR"]?
      return parse_ip(value) unless value.empty?
    end

    if value = request.headers["REMOTE_ADDR"]?
      return parse_ip(value) unless value.empty?
    end

    "unknown"
  end

  private def parse_ip(value : String) : String
    value.split(',').first.strip
  end
end
