class Auth::UserSerializer < ModelSerializer
  protected def fields
    record = @record.as(Auth::User)

    {
      id:                        record.hashed_id,
      first_name:                record.first_name,
      last_name:                 record.last_name,
      email:                     record.email,
      role:                      record.role,
      is_email_address_verified: record.is_email_address_verified,
      locale:                    record.locale,
      timezone_offset_seconds:   record.timezone_offset_seconds,
    }
  end
end
