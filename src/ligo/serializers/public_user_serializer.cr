class PublicUserSerializer < ModelSerializer
  protected def fields
    record = @record.as(Ligo::User)

    {
      id:                      record.hashed_id,
      first_name:              record.first_name,
      last_name:               record.last_name,
      locale:                  record.locale,
      timezone_offset_seconds: record.timezone_offset_seconds,
      profile_picture:         fetch_profile_picture_url,
    }
  end

  private def fetch_profile_picture_url : String?
    record = @record.as(Ligo::User)

    picture_id = record.uploaded_profile_picture_file_id
    return nil unless picture_id

    Marten.routes.reverse("uploaded_file_show", id: picture_id.to_s)
  end
end
