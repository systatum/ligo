module Antrikan
  class SpaceSerializer < ModelSerializer
    protected def fields
      record = @record.as(Space)

      {
        id:                        record.hashed_id,
        code:                      record.code,
        name:                      record.name,
        need_manual_approval:      record.need_manual_approval,
        has_operating_hours:       record.has_operating_hours,
        require_registered_queuer: record.require_registered_queuer,
        logo:                      fetch_logo_url,
        carousel_images:           fetch_carousel_images,
        business_id:               record.owner!.hashed_id,
        address:                   record.address,
        phone:                     record.phone,
        email:                     record.email,
        average_rating:            record.average_rating,
        review_count:              record.review_count,
      }
    end

    private def fetch_logo_url : String?
      record = @record.as(Space)

      logo_id = record.logo_file_id
      return nil unless logo_id

      Marten.routes.reverse("uploaded_file_show", id: logo_id.to_s)
    end

    private def fetch_carousel_images
      record = @record.as(Space)

      ids = record.carousel_image_ids.try(&.ids) || [] of String
      files_by_id = UploadedFile.filter(id__in: ids.map { |id| UUID.new(id) }).index_by(&.id.to_s)

      ids.compact_map { |id| files_by_id[id]? }.map { |file| UploadedFileSerializer.soft_serialize(file) }
    end
  end
end
