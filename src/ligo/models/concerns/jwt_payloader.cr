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
    ver : Int32,

    # identity claims
    given_name : String?,
    family_name : String?,
    email : String?,
    role : Int32 | Int64 do
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

    # Resolves the user a JWT was issued for, rejecting it if the user's
    # password has changed since (puat mismatch means the token is stale).
    def self.find_by_jwt_token(jwt_token) : self?
      payload = decode_jwt_token(jwt_token)

      user = self.get(id: payload["id"].as_i64)
      return nil unless user
      return nil unless user.password_updated_at!.to_unix_f == payload["puat"].as_f

      user
    rescue
      nil
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
      ver: 2,
      given_name: first_name,
      family_name: last_name,
      email: email,
      role: role!
    )

    JWT.encode(
      payload,
      Marten.settings.secret_key,
      JWT::Algorithm::HS256
    )
  end
end
