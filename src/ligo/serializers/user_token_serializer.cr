class UserTokenSerializer < ModelSerializer
  protected def fields
    record = @record.as(Ligo::User)

    {
      id:        record.hashed_id,
      email:     record.email,
      jwt_token: record.jwt_token,
    }
  end
end
