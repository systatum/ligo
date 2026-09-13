class UserSerializer < ModelSerializer
  protected def fields
    record = @record.as(Ligo::User)

    {
      id:                        record.hashed_id,
      first_name:                record.first_name,
      last_name:                 record.last_name,
      email:                     record.email,
      role:                      record.role,
      is_email_address_verified: record.is_email_address_verified,
      locale:                    record.locale,
      timezone_offset_seconds:   record.timezone_offset_seconds,
      profile_picture:           fetch_profile_picture_url,
    }
  end

  private def fetch_profile_picture_url : String?
    record = @record.as(Ligo::User)

    picture_id = record.uploaded_profile_picture_file_id
    return nil unless picture_id

    Marten.routes.reverse("uploaded_file_show", id: picture_id.to_s)
  end
end
