module JwtPayloader
  record JWTPayload,
    # the user ID, used to resolve who issued a request
    id : Int32 | Int64,

    # date when the token is issued
    iat : Int64,

    # expiry date of the token
    exp : Int64,

    # "password last updated at" if doesn't match with the database
    # then we should not accept the token, regarding it as obsolete
    puat : Float64,

    # versioning of the token structure
    ver : Int32 do
    include JSON::Serializable
  end

  macro included
    def self.decode_jwt_token(jwt_token) : JSON::Any
      payload, _ = JWT.decode(
        jwt_token,
        Marten.settings.secret_key,
        JWT::Algorithm::HS256
      )

      payload
    end

    def self.find_by_jwt_token(jwt_token)
      payload = decode_jwt_token(jwt_token)
      User.get!(id: payload["id"].as_i64)
    end
  end

  # generates a new JWT token every invocation
  def jwt_token
    reload

    payload = JWTPayload.new(
      id: id!,
      iat: Time.utc.to_unix,
      exp: Time.utc.to_unix + (365 * 24 * 60 * 60), # set to expire in a year!
      puat: password_updated_at!.to_unix_f,
      ver: 1,
    )

    return JWT.encode(
      payload,
      Marten.settings.secret_key,
      JWT::Algorithm::HS256
    )
  end
end
