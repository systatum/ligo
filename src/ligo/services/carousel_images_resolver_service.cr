require "../handlers/concerns/file_uploader"

# Resolves a `carousel_images` schema field with each entry either `{keep_id: <uuid>}`
# or a fresh upload payload into the ordered list of UploadedFile ids to persist
class CarouselImagesResolverService < BaseService(Array(String))
  include FileUploader

  def initialize(
    @entries : Array(JSON::Any | JSON::Serializable | Nil),
    @current_ids : Array(String) = [] of String,
  )
  end

  def run : ServiceResult(Array(String))
    ids = @entries.map do |entry|
      payload = entry.as(CarouselImagePayload)

      if (keep_id = payload.keep_id)
        unless @current_ids.includes?(keep_id)
          return failure(:carousel_images, "keep_id does not reference an existing image")
        end
        keep_id
      else
        raw_payload = FilePayload.from_json({
          base64_bytes: payload.base64_bytes,
          mimetype:     payload.mimetype,
        }.to_json)
        upload_image(raw_payload).not_nil!.to_s
      end
    end

    success(ids)
  end
end
