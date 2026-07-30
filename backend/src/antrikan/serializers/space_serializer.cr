module Antrikan
  class SpaceSerializer < ModelSerializer
    protected def fields
      record = @record.as(Space)

      {
        id:                        record.hashed_id,
        code:                      record.code,
        name:                      record.name,
        description:               record.description,
        need_manual_approval:      record.need_manual_approval,
        has_operating_hours:       record.has_operating_hours,
        require_registered_queuer: record.require_registered_queuer,
        allow_anonymous_reviewer:  record.allow_anonymous_reviewer,
        logo:                      fetch_logo_url,
        carousel_images:           fetch_carousel_images,
        business_id:               record.owner!.hashed_id,
        address:                   record.address,
        address_city_code:         record.address_city_code,
        address_postal_code:       record.address_postal_code,
        latitude:                  record.latitude,
        longitude:                 record.longitude,
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
      fetch_uploaded_files(record.carousel_image_ids.try(&.ids))
    end
  end
end
