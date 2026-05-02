module Antrikan
  class ItemSerializer < ModelSerializer
    protected def fields
      record = @record.as(Item)

      {
        id:           record.slug,
        channel_id:   record.channel!.hashed_id,
        name:         record.name,
        order:        record.order,
        daily_cap:    record.daily_cap,
        is_monitored: record.is_monitored,
        description:  record.description,
        main_image:   fetch_main_image_url,
      }
    end

    private def fetch_main_image_url : String?
      record = @record.as(Item)

      image_id = record.main_image_file_id
      return nil unless image_id

      Marten.routes.reverse("uploaded_file_show", id: image_id.to_s)
    end
  end
end
