module RequestCacher
  IMMUTABLE_DATA_CONTROL_HEADER = "public, max-age=604800, immutable"

  def set_response_cache_headers!(
    cache_control : String,
    etag : String? = nil,
    last_modified : Time? = nil,
  )
    response!.headers["Cache-Control"] = cache_control
    response!.headers["ETag"] = etag if etag
    response!.headers["Last-Modified"] = HTTP.format_time(last_modified.to_utc) if last_modified
  end

  def set_response_immutable!(
    etag : String? = nil,
    last_modified : Time? = nil,
  )
    set_response_cache_headers!(
      IMMUTABLE_DATA_CONTROL_HEADER,
      etag: etag,
      last_modified: last_modified
    )
  end

  private def request_not_modified?(etag : String? = nil, last_modified : Time? = nil) : Bool
    return etag_matches?(etag.not_nil!) if etag
    return last_modified_not_modified?(last_modified.not_nil!) if last_modified
    false
  end

  private def etag_matches?(etag : String) : Bool
    if_none_match = request.headers["If-None-Match"]?
    return false unless if_none_match

    normalized_etag = normalize_etag(etag)

    if_none_match.split(',').any? do |candidate|
      normalized_candidate = normalize_etag(candidate)
      normalized_candidate == "*" || normalized_candidate == normalized_etag
    end
  end

  private def last_modified_not_modified?(last_modified : Time) : Bool
    if_modified_since = request.headers["If-Modified-Since"]?
    return false unless if_modified_since

    last_modified_utc = last_modified.to_utc
    parsed_if_modified_since = HTTP.parse_time(if_modified_since)

    last_modified_utc.to_unix <= parsed_if_modified_since.not_nil!.to_unix
  rescue
    false
  end

  # removes extra stuff
  private def normalize_etag(value : String) : String
    normalized = value.strip
    normalized = normalized[2..] if normalized.starts_with?("W/")
    normalized
  end

  private def build_etag(*parts) : String
    %("#{parts.to_a.map(&.to_s).join("-")}")
  end
end
