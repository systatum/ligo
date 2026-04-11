module Antrikan
  class ChannelSerializer < ModelSerializer
    protected def fields
      record = @record.as(Channel)

      {
        id:          record.hashed_id,
        name:        record.name,
        description: record.description,
        logo:        fetch_logo_url,
      }
    end

    private def fetch_logo_url : String?
      record = @record.as(Channel)

      logo_id = record.logo_file_id
      return nil unless logo_id

      Marten.routes.reverse("uploaded_file_show", id: logo_id.to_s)
    end
  end
end
