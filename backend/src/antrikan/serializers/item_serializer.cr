module Antrikan
  class ItemSerializer < ModelSerializer
    protected def fields
      record = @record.as(Item)

      {
        id:              record.slug,
        channel_id:      record.channel!.hashed_id,
        name:            record.name,
        order:           record.order,
        daily_cap:       record.daily_cap,
        unit_price:      record.unit_price,
        unit_currency:   record.unit_currency,
        is_monitored:    record.is_monitored,
        description:     record.description,
        main_image:      fetch_main_image_url,
        carousel_images: fetch_carousel_images,
      }
    end

    private def fetch_main_image_url : String?
      record = @record.as(Item)

      image_id = record.main_image_file_id
      return nil unless image_id

      Marten.routes.reverse("uploaded_file_show", id: image_id.to_s)
    end

    private def fetch_carousel_images
      record = @record.as(Item)

      ids = record.carousel_image_ids.try(&.ids) || [] of String
      files_by_id = UploadedFile.filter(
        id__in: ids.map { |id| UUID.new(id) }
      ).index_by(&.id.to_s)

      ids.compact_map { |id| files_by_id[id]? }.map do |file|
        UploadedFileSerializer.soft_serialize(file)
      end
    end
  end
end
